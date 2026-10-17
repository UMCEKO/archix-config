-- modules/packages.nix: the shared package set, nixpkgs names mapped to Arch, CachyOS and AUR ones.
return {
  packages = {
    -- CLI and shell tools
    "wget", "curl", "aria2", "rsync", "pv", "file", "tree", "tmux",
    "ripgrep", "fd", "eza", "bat", "zoxide", "fzf", "jq", "go-yq", "just",
    "btop", "htop", "fastfetch", "starship", "nushell", "rclone",
    "yt-dlp", "ncdu", "duf", "tokei", "trash-cli", "pandoc-cli", "tesseract", "tesseract-data-eng",
    "unzip", "7zip", "unrar", "sshpass", "parted", "net-tools", "wtype",
    "nmap", "tcpdump", "mtr", "traceroute", "whois", "ethtool", "usbutils", "pciutils", "dmidecode", "bind",

    -- development
    "git", "neovim", "vim", "opencode",
    "rustup", "zig", "nasm", "mono", "uv", "pyenv",
    "nodejs", "npm", "python", "go", "netbird",
    "github-cli", "github-desktop", "meld",
    "kubectl", "helm", "k9s", "argocd", "pulumi",
    "aws-cli-v2", "google-cloud-cli", "stripe-cli",
    "mongosh-bin", -- check
    "openai-codex", "t3code-bin",
    "android-tools",
    "android-apktool-bin", -- the source recipe wants a newer JDK than Arch ships
    "jadx", "dioxus-cli",
    "jdk-temurin", -- check
    "flutter-bin", -- check
    "tree-sitter-cli", "imagemagick",
    "terraform", "kubeseal",
    "bun", "protobuf", "pkgconf", "cmake", "mold", "sccache", "grpcurl",
    "sqlx-cli", "sea-orm-cli", "cargo-expand", "cargo-machete", "cargo-license",
    "cargo-zigbuild", "cargo-xwin",
    "postgresql",
    "valkey", -- check
    "shopify-cli",

    -- Neovim runtime deps
    "gcc", "make", "luarocks", "lua51", "lazygit", "ghostscript", "tectonic", "mermaid-cli",
    "zed", "sublime-merge", "hoppscotch-bin",

    -- GUI apps
    "brave-bin", "google-chrome",
    "torbrowser-launcher", -- check
    "element-desktop",
    "slack-desktop", "telegram-desktop",
    "hearth-bin", "zapfast-bin",
    "spotify", -- check
    "obsidian", "gparted", "thunderbird",
    "bitwarden", "keepassxc", "anydesk-bin",
    "rustdesk-bin", -- check
    "onlyoffice-bin", "figma-linux",
    "photocraft-bin",
    "vlc", "haruna", "gpu-screen-recorder", "krita", "mpv",
    "obs-studio", "obs-vkcapture", "lib32-obs-vkcapture", "obs-multi-rtmp", "obs-pipewire-audio-capture",
    "qdirstat", "quickemu", "unetbootin", "pavucontrol",
    "stremio-linux-shell",
    "libpulse",
    "kdenlive", "filelight", "okular", "kcalc",
    "nautilus", "inkscape", "kopuz-bin", "audacity",
    "qpwgraph", "carla", "openvpn", "cemu", "polychromatic",

    -- Wayland / Hyprland desktop stack
    "psmisc", "libnotify", "rofi", "wlogout",
    "nwg-displays", "nwg-look",
    "hyprlock", "hyprpicker", "hyprshade", "hyprsunset", "hyprpolkitagent",
    "xwayland-satellite",
    "grim", "slurp", "satty", "grimblast-git", "wf-recorder", "wl-clipboard", "cliphist",
    "nsxiv", "gromit-mpx", "kdotool", "matugen", "cava", "waypipe",
    "kitty", "ghostty", "reqable-bin",
    "brightnessctl", "playerctl",

    -- theming
    "adw-gtk-theme",
    "bibata-cursor-theme", -- check
    "python-pywal", -- check
    "papirus-icon-theme",

    -- hardware and misc
    "vulkan-tools", "iw",
    "prismlauncher", "osu-lazer-bin",
  },
}
