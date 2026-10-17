-- hosts/desktop/system-tweaks.nix: services, sysctls, zram, swap, oomd, sched-ext, watchdog and the wake-fault mitigations.
local unit = archix.formats.systemd
local sleep_targets = { "suspend.target", "hibernate.target", "hybrid-sleep.target", "suspend-then-hibernate.target" }

return {
  packages = {
    "plymouth",
    "linux-cachyos-headers",
    "v4l2loopback-dkms",
    "iriunwebcam-bin",
    "avahi",
    "nss-mdns",
    "libvirt",
    "qemu-desktop",
    "dnsmasq",
    "openssh",
    "ananicy-cpp",
    "cachyos-ananicy-rules",
    "irqbalance",
    "mullvad-vpn",
    "flatpak",
    "cpupower",
    "zram-generator",
  },

  users = { umceko = { groups = { "libvirt" } } },

  modprobe = {
    blacklist = "blacklist wacom\n",
    v4l2loopback = 'options v4l2loopback exclusive_caps=1 devices=1 card_label="Iriun Webcam,Iriun Webcam #2,Iriun Webcam #3,Iriun Webcam #4"\n',
  },
  kernel_modules = { "v4l2loopback", "snd-aloop" },

  environment = {
    variables = {
      GBM_BACKEND = "nvidia-drm",
      __GLX_VENDOR_LIBRARY_NAME = "nvidia",
      LIBVA_DRIVER_NAME = "nvidia",
    },
  },

  services = {
    ["avahi-daemon.service"] = true,
    ["libvirtd.service"] = true,
    ["sshd.service"] = true,
    ["ananicy-cpp.service"] = true,
    ["irqbalance.service"] = true,
    ["mullvad-daemon.service"] = true,
    ["cpufreq.service"] = true,
    ["systemd-oomd.service"] = true,
    ["swap-swapfile.swap"] = true,
  },

  -- 4698: Iriun phone discovery and stream; 25565: Minecraft; 22: sshd; 5353: avahi
  firewall = {
    allowed_tcp_ports = { 22, 25565 },
    allowed_udp_ports = { 4698, 5353 },
    -- libvirt's dnsmasq answers DHCP and DNS on virbr0, which iptables let through on NixOS
    trusted_interfaces = { "virbr0" },
  },

  udev_rules = {
    ["90-wake-fault"] = [[
ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="05e3", ATTRS{idProduct}=="0610", ATTR{power/wakeup}="enabled"
ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x0c0330", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x030000", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{class}=="0x040300", ATTR{power/control}="on"
]],
  },

  sysctl = {
    ["vm.max_map_count"] = 2147483642,
    ["vm.swappiness"] = 100,
    ["vm.page-cluster"] = 0,
    ["vm.vfs_cache_pressure"] = 50,
    ["kernel.split_lock_mitigate"] = 0,
    ["net.core.default_qdisc"] = "cake",
    ["net.ipv4.tcp_congestion_control"] = "bbr",
    ["kernel.sysrq"] = 1,
    ["kernel.softlockup_panic"] = 1,
    ["kernel.hardlockup_panic"] = 1,
    ["kernel.hung_task_panic"] = 1,
    ["kernel.panic_on_oops"] = 1,
    ["kernel.panic"] = 20,
  },

  files = {
    -- the driver's "No VidMem Reuse" profile lists Hyprland but not niri, whose VRAM use then balloons
    ["/etc/nvidia/nvidia-application-profiles-rc.d/50-niri.json"] = {
      text = archix.formats.json {
        rules = { { pattern = { feature = "procname", matches = "niri" }, profile = "Limit Free Buffer Pool On Wayland Compositors" } },
        profiles = { { name = "Limit Free Buffer Pool On Wayland Compositors", settings = { { key = "GLVidHeapReuseRatio", value = 0 } } } },
      },
    },
    ["/etc/systemd/zram-generator.conf"] = {
      text = "[zram0]\nzram-size = ram / 2\ncompression-algorithm = zstd\nswap-priority = 5\n",
    },
    ["/etc/systemd/system/-.slice.d/10-oomd.conf"] = {
      text = "[Slice]\nManagedOOMMemoryPressure=kill\nManagedOOMMemoryPressureLimit=80%\n",
    },
    ["/etc/systemd/system/user.slice.d/10-oomd.conf"] = {
      text = "[Slice]\nManagedOOMMemoryPressure=kill\nManagedOOMMemoryPressureLimit=80%\n",
    },
    ["/etc/systemd/user/slice.d/10-oomd.conf"] = {
      text = "[Slice]\nManagedOOMMemoryPressure=kill\nManagedOOMMemoryPressureLimit=80%\n",
    },
    -- SP5100 TCO watchdog: PID 1 pets it, so a total wedge resets the board within 30s
    ["/etc/systemd/system.conf.d/10-watchdog.conf"] = { text = "[Manager]\nRuntimeWatchdogSec=30s\n" },
    -- the whole file, as the NixOS module writes it; Hyprland in the root cgroup lost Ctrl+Alt+Fn
    ["/etc/ananicy.d/ananicy.conf"] = {
      text = [[
check_freq = 15
cgroup_load = true
type_load = true
rule_load = true
apply_nice = true
apply_latnice = true
apply_ionice = true
apply_sched = true
apply_oom_score_adj = true
apply_cgroup = true
loglevel = info
log_applied_rule = false
cgroup_realtime_workaround = false
]],
    },
  },

  units = {
    ["cpufreq.service"] = unit {
      Unit = { Description = "CPU frequency governor" },
      Service = { Type = "oneshot", RemainAfterExit = true, ExecStart = "/usr/bin/cpupower frequency-set -g performance" },
      Install = { WantedBy = "multi-user.target" },
    },
    -- the Intel 2.5GbE (igc) NIC drops after suspend
    ["igc-resume.service"] = unit {
      Unit = { Description = "Reload igc module after resume", After = sleep_targets },
      Service = { Type = "oneshot", ExecStart = { "/usr/bin/modprobe -r igc", "/usr/bin/modprobe igc" } },
      Install = { WantedBy = sleep_targets },
    },
    -- second swap tier below zram's priority 5; in its own subvolume so root snapshots keep working
    ["swap-swapfile.swap"] = unit {
      Unit = { Description = "Swap file below zram", ConditionPathExists = "/swap/swapfile" },
      Swap = { What = "/swap/swapfile", Priority = 1 },
      Install = { WantedBy = "swap.target" },
    },
  },

  hooks = {
    swapfile = {
      run = [[
[ -d /swap ] || btrfs subvolume create /swap
[ -f /swap/swapfile ] || btrfs filesystem mkswapfile --size 32g /swap/swapfile
systemctl start swap-swapfile.swap
]],
    },
  },
}
