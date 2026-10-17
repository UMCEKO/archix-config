-- home/common.nix: umceko's dotfiles, shell, git, kitty and the DMS session unit.
local live = {
  "hypr", "niri", "rofi", "wlogout", "matugen", "sidepad", "Iriun", "Kvantum", "vim", "ohmyposh", "nvim", "fish",
  "ml4w", "quickshell", "DankMaterialShell", "danksearch",
}

-- Stamps config/DankMaterialShell/hosts/<hostname>.json over the shared settings.json before DMS reads it.
local dms_host_settings = [[
#!/bin/sh
set -eu
dir="$HOME/.config/DankMaterialShell"
base="$dir/settings.json"
over="$dir/hosts/$(cat /etc/hostname).json"
[ -f "$base" ] && [ -f "$over" ] || exit 0
merged=$(jq -s '.[0] * .[1]' "$base" "$over")
[ "$merged" = "$(cat "$base")" ] && exit 0
printf '%s' "$merged" > "$base.new"
mv -f "$base.new" "$base"
]]

-- git clean filter: drops every key a host file overrides, so host-specific values never reach the repo.
local dms_settings_clean = [=[
#!/bin/sh
set -eu
set -- config/DankMaterialShell/hosts/*.json
[ -e "$1" ] || exec cat
keys=$(jq -s 'add | keys' "$@")
exec jq --argjson k "$keys" 'delpaths([$k[] | [.]])'
]=]

local files = {
  [".local/share/color-schemes/CatppuccinMochaMauve.colors"] = { source = "config/color-schemes/CatppuccinMochaMauve.colors" },
  [".claude/CLAUDE.md"] = { link = "/home/umceko/.claude-shared/CLAUDE.md" },
  [".config/fastfetch/config.jsonc"] = { source = "config/fastfetch/config.json" },
  [".local/bin/dms-apply-host-settings"] = { text = dms_host_settings, executable = true },
  [".local/bin/dms-settings-clean"] = { text = dms_settings_clean, executable = true },
}
for _, name in ipairs(live) do
  files[".config/" .. name] = { source = "config/" .. name, live = true }
end

return {
  packages = { "jq", "oh-my-zsh-git", "git" },
  home = {
    user = "umceko",
    files = files,
    systemd = {
      services = {
        ["dms-shell"] = {
          Unit = {
            Description = "DankMaterialShell (Hyprland/niri session)",
            After = "graphical-session.target",
            PartOf = "graphical-session.target",
          },
          Service = {
            Type = "simple",
            ExecStartPre = "%h/.local/bin/dms-apply-host-settings",
            ExecStart = "/usr/bin/dms run --session -c %h/.config/quickshell/dms",
            Restart = "on-failure",
            RestartSec = 2,
            Slice = "session.slice",
          },
        },
        ["cache-trim"] = {
          Unit = { Description = "Weekly Go build cache clear and uv cache prune" },
          Service = { Type = "oneshot", ExecStart = { "/usr/bin/go clean -cache", "/usr/bin/uv cache prune" } },
        },
      },
      timers = {
        ["cache-trim"] = {
          Timer = { OnCalendar = "weekly", Persistent = true },
          Install = { WantedBy = "timers.target" },
        },
      },
    },
  },

  mime_apps = {
    enable = true,
    default_applications = {
      ["x-scheme-handler/http"] = "brave-browser.desktop",
      ["x-scheme-handler/https"] = "brave-browser.desktop",
      ["text/html"] = "brave-browser.desktop",
      ["application/xhtml+xml"] = "brave-browser.desktop",
      ["inode/directory"] = "org.gnome.Nautilus.desktop",
      ["x-scheme-handler/bitwarden"] = "bitwarden.desktop",
      ["x-scheme-handler/claude-cli"] = "claude-code-url-handler.desktop",
    },
  },

  programs = {
    kitty = {
      enable = true,
      font = { name = "JetBrainsMono Nerd Font", size = 12 },
      settings = {
        bold_font = "auto",
        italic_font = "auto",
        bold_italic_font = "auto",
        remember_window_size = "no",
        initial_window_width = 950,
        initial_window_height = 500,
        cursor_blink_interval = "0.5",
        cursor_stop_blinking_after = 1,
        scrollback_lines = 2000,
        wheel_scroll_min_lines = 1,
        enable_audio_bell = "no",
        window_padding_width = 10,
        hide_window_decorations = "yes",
        background_opacity = "0.7",
        dynamic_background_opacity = "yes",
        confirm_os_window_close = 0,
        selection_foreground = "none",
        selection_background = "none",
      },
      extra_config = "include colors-matugen.conf\ncursor_trail 1\n",
    },

    -- settings stay empty: config.jsonc is the repo's config/fastfetch/config.json, set in files above
    fastfetch = { enable = true },

    zsh = {
      enable = true,
      -- oh-my-zsh runs compinit itself, as it did under Home Manager
      enable_completion = false,
      autosuggestion = { enable = true },
      syntax_highlighting = { enable = true },
      history = { size = 10000, save = 10000 },
      shell_aliases = {
        c = "clear",
        nf = "fastfetch",
        pf = "fastfetch",
        ff = "fastfetch",
        ls = "eza -a --icons=always",
        ll = "eza -al --icons=always",
        lt = "eza -a --tree --level=1 --icons=always",
        v = "$EDITOR",
        vim = "$EDITOR",
        wifi = "nmtui",
        shutdown = "systemctl poweroff",
        k = "kubectl",
        gs = "git status",
        ga = "git add",
        gc = "git commit -m",
        gp = "git push",
        gpl = "git pull",
        gst = "git stash",
        gsp = "git stash; git pull",
        gfo = "git fetch origin",
        gcheck = "git checkout",
        gcredential = "git config credential.helper store",
      },
      init_content = [=[
ZSH=/usr/share/oh-my-zsh
ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
plugins=(git)
source $ZSH/oh-my-zsh.sh
# oh-my-zsh's history defaults would otherwise win over the history options above
HISTSIZE=10000
SAVEHIST=10000
setopt NO_EXTENDED_HISTORY NO_HIST_EXPIRE_DUPS_FIRST

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
setopt append_history

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# oh-my-zsh aliases md='mkdir -p', which would make the function below a parse error
unalias md 2>/dev/null
md() { pandoc "$1" -s -o /tmp/md.html && xdg-open /tmp/md.html; }

if [[ -o interactive ]]; then
  fastfetch
fi
]=],
    },

    starship = { enable = true },

    git = {
      enable = true,
      settings = {
        user = { email = "umutcevdetkocak@gmail.com", name = "umceko" },
        -- empty so git prompts on the tty instead of Plasma's ksshaskpass, which can't register under Hyprland
        core = { askpass = "" },
        filter = { ["dms-settings"] = { clean = "/home/umceko/.local/bin/dms-settings-clean" } },
        credential = {
          helper = "/usr/lib/git-core/git-credential-libsecret",
          ["https://github.com"] = { helper = { "", "!gh auth git-credential" } },
          ["https://gist.github.com"] = { helper = { "", "!gh auth git-credential" } },
        },
      },
    },
  },

  hooks = {
    -- DMS loads its fonts by relative path from the editable clone, whose assets/ isn't in git; fetch them per dms version.
    dms_clone_assets = {
      user = "umceko",
      run = [[
clone="$HOME/.config/quickshell/dms"
[ -d "$clone" ] || exit 0
version=$(pacman -Q dms-shell | awk '{print $2}' | cut -d- -f1)
src="$HOME/.cache/archix/dms-src/$version"
if [ ! -d "$src/quickshell/assets" ]; then
  rm -rf "$src"
  git clone -q --depth 1 --branch "v$version" --recurse-submodules --shallow-submodules \
    https://github.com/AvengeMedia/DankMaterialShell "$src"
  [ -e "$src/quickshell/assets/fonts" ] || ln -s "$src/dank-qml-common/DankCommon/assets/fonts" "$src/quickshell/assets/fonts"
fi
relink() {
  if [ -L "$2" ]; then ln -sfn "$1" "$2"
  elif [ -e "$2" ]; then
    if [ -e "$2.pre-symlink" ]; then rm -rf "$2"; else mv "$2" "$2.pre-symlink"; fi
    ln -s "$1" "$2"
  else ln -s "$1" "$2"
  fi
}
relink "$src/quickshell/assets" "$clone/assets"
relink "$src/quickshell/translations" "$clone/translations"
]],
    },
    -- niri's config.kdl includes host.kdl, a gitignored link to hosts/<hostname>.kdl
    niri_host_config = {
      user = "umceko",
      run = 'ln -sfn "hosts/$(cat /etc/hostname).kdl" "$HOME/.config/niri/host.kdl"\n',
    },
    dms_host_settings = {
      user = "umceko",
      run = '"$HOME/.local/bin/dms-apply-host-settings"\n',
    },
  },
}
