-- hosts/desktop/gaming.nix: Steam with Proton-GE and proton-cachyos, gamescope, gamemode and the launchers.
local sniper = [[
"compatibilitytools"
{
  "compat_tools"
  {
    "SLR-sniper-manual"
    {
      "install_path" "/home/umceko/.local/share/Steam/steamapps/common/SteamLinuxRuntime_sniper"
      "display_name" "Steam Linux Runtime 3.0 (sniper) [manual]"
      "from_oslist"  "linux"
      "to_oslist"    "linux"
    }
  }
}
]]

return {
  imports = { "modules.vice" },
  config = {
    vice = { enable = true },

    packages = {
      "steam",
      "gamescope",
      "gamescope-session-steam-git", -- check
      "gamemode",
      "lib32-gamemode",
      "proton-ge-custom-bin",
      "proton-cachyos-slr", -- check
      "mangohud",
      "lib32-mangohud",
      "protonup-qt",
      "protontricks",
      "r2modman-bin", -- check
      "wine",
      "winetricks",
      "lutris",
      "heroic-games-launcher-bin",
    },

    users = { umceko = { groups = { "gamemode" } } },

    -- programs.steam remotePlay and dedicatedServer openFirewall
    firewall = {
      allowed_tcp_ports = { 27036, 27015 },
      allowed_udp_ports = { 27015 },
      allowed_udp_port_ranges = { { from = 27031, to = 27036 } },
    },

    files = {
      ["/etc/gamemode.ini"] = { text = archix.formats.ini { general = { renice = 10, inhibit_screensaver = 1 } } },
    },

    home = {
      files = {
        -- gives Steam's own sniper runtime a display_name so native games can select it
        [".local/share/Steam/compatibilitytools.d/SLR-sniper-manual/compatibilitytool.vdf"] = { text = sniper },
      },
    },

    hooks = {
      -- programs.gamescope.capSysNice
      gamescope_cap = {
        run = "getcap /usr/bin/gamescope | grep -q cap_sys_nice || setcap cap_sys_nice=eip /usr/bin/gamescope\n",
      },
    },
  },
}
