-- hosts/desktop/peripherals.nix: Bluetooth, Razer, OpenRGB, the SteelSeries headset, Wooting, tablets, uinput, fwupd.
local unit = archix.formats.systemd

return {
  packages = {
    "bluez",
    "bluez-utils",
    "openrazer-daemon",
    "openrazer-driver-dkms",
    "openrgb",
    "i2c-tools",
    "headsetcontrol",
    "chatmixd-git",
    "wootility",
    "wooting-bg-service",
    "opentabletdriver",
    "fwupd",
  },

  users = { umceko = { groups = { "plugdev" } } },
  groups = { plugdev = { system = true }, uinput = { system = true } },

  -- openrgb's motherboard i2c access on AMD, plus uinput
  kernel_modules = { "i2c-dev", "i2c-piix4", "uinput" },
  modprobe = { opentabletdriver = "blacklist hid_uclogic\n" },
  udev_rules = {
    ["99-uinput"] = 'SUBSYSTEM=="misc", KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"\n',
  },

  services = {
    ["bluetooth.service"] = true,
    ["openrgb.service"] = true,
  },
  units = {
    ["openrgb.service"] = unit {
      Unit = { Description = "OpenRGB server daemon" },
      Service = {
        StateDirectory = "OpenRGB",
        WorkingDirectory = "/var/lib/OpenRGB",
        ExecStart = "/usr/bin/openrgb --server --server-port 6742",
        Restart = "always",
      },
      Install = { WantedBy = "multi-user.target" },
    },
  },

  user_services = {
    ["chatmixd.service"] = true,
    ["openrazer-daemon.service"] = true,
    ["opentabletdriver.service"] = true,
    ["wooting-bg-service.service"] = true,
  },
  -- a user unit, not Wootility's own autostart toggle, so it only runs in a graphical session
  user_units = {
    ["wooting-bg-service.service"] = unit {
      Unit = {
        Description = "Wooting background service (app linking, light indicators)",
        After = "graphical-session.target",
        PartOf = "graphical-session.target",
        ConditionEnvironment = { "|WAYLAND_DISPLAY", "|DISPLAY" },
      },
      Service = {
        Type = "simple",
        ExecStart = "/usr/bin/wooting-bg-service",
        Restart = "on-failure",
        RestartSec = 3,
      },
      Install = { WantedBy = "graphical-session.target" },
    },
  },
}
