-- hosts/desktop/home.nix: HUSH (needs the 4090's CUDA), proton-cachyos for Steam and umu, OpenComposite, the 4K KWin bits.
local proton = "/usr/share/steam/compatibilitytools.d/proton-cachyos-slr"

-- same as plasma_rc.lua's rc(): keys stay unlocked, like plasma-manager
local function rc(values)
  return { merge = { format = "kconfig", values = values }, mutable = true }
end

return {
  packages = { "hush-mic" },
  home = {
    files = {
      -- stable PROTONPATH for umu-launcher
      [".local/share/proton-cachyos"] = { link = proton },
      [".local/share/opencomposite"] = { link = "/opt/opencomposite" },
      -- 1.7 suits the desktop's 4K panels, not the laptop
      [".config/kwinrc"] = rc { Xwayland = { Scale = 1.7 } },
      -- the captured rule has no match criteria, only tearingrule=2; reproduced as it is on the desktop
      [".config/kwinrulesrc"] = rc {
        General = { count = 1, rules = "finals-force-tearing" },
        ["finals-force-tearing"] = { Description = "Finals Force Tearing", tearingrule = 2 },
      },
    },
    systemd = {
      services = {
        -- the Maxine runtime is downloaded into the data dir by the GUI on first launch; until then hushd exits
        hush = {
          Unit = {
            Description = "HUSH denoiser daemon (NVIDIA Maxine virtual microphone)",
            After = { "pipewire.service", "wireplumber.service" },
            Wants = "pipewire.service",
          },
          Service = {
            ExecStart = "/usr/bin/hushd",
            Environment = "LD_LIBRARY_PATH=%h/.local/share/hush/sdk/2.1.0/nvafx/lib:%h/.local/share/hush/sdk/2.1.0/external/cuda/lib:%h/.local/share/hush/sdk/2.1.0/features/denoiser/lib",
            Restart = "on-failure",
            RestartSec = 5,
          },
          Install = { WantedBy = "default.target" },
        },
      },
    },
  },
  hooks = {
    -- BSManager wants a writable Proton folder with files/bin/wine64; refreshed only when the package changes
    proton_cachyos_compat_tool = {
      user = "umceko",
      run = 'src="' .. proton .. '"\n' .. [[
dst="$HOME/.local/share/Steam/compatibilitytools.d/proton-cachyos"
[ -d "$src" ] || exit 0
stamp=$(pacman -Q proton-cachyos-slr)
[ "$(cat "$dst/.archix-version" 2>/dev/null)" = "$stamp" ] && exit 0
rm -rf "$dst"
mkdir -p "$dst"
cp -rT --no-preserve=ownership "$src" "$dst"
chmod -R u+w "$dst"
ln -sf wine "$dst/files/bin/wine64"
echo "$stamp" > "$dst/.archix-version"
]],
    },
  },
}
