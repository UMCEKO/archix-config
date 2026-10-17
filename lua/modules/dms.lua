-- modules/dms.nix: DankMaterialShell, started only from the Hyprland/niri autostart, never from Plasma.
return {
  packages = { "dms-shell", "quickshell", "dsearch-bin" },
  patches = { quickshell = { "patches/quickshell-virtual-audio-source.patch" } },
  user_services = { ["dsearch.service"] = true },
  home = {
    files = {
      -- the packaged unit would leak DMS into Plasma; home.lua's dms-shell.service replaces it
      [".config/systemd/user/dms.service"] = { link = "/dev/null" },
    },
  },
}
