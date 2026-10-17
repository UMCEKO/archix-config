-- hosts/desktop: Ryzen 9 7900X + RTX 4090 + AMD iGPU; everything true of this box and nothing else.
return {
  imports = {
    "modules.gaming",
    "modules.peripherals",
    "modules.vr",
    "modules.drives",
    "modules.tweaks",
    "modules.nginx",
    "modules.zapret",
    "modules.dns",
    "modules.desktop_home",
  },
  config = {
    hostname = "desktop",
    boot = {
      loader = "systemd-boot",
      kernel = "linux-cachyos",
      microcode = { "amd-ucode.img" },
      -- boot.loader.systemd-boot.memtest86: a single overnight error means stop debugging software
      extra_entries = { ["memtest86+.conf"] = "title Memtest86+\nefi /memtest86+/memtest.efi" },
    },
    kernel_params = {
      "root=UUID=00000000-0000-0000-0000-000000000000", -- set at install
      "rw",
      "rootflags=subvol=/@", -- check
      "zswap.enabled=0",
      "loglevel=3",
      "vsyscall=emulate",
      "pcie_aspm.policy=performance",
      "pcie_ports=native",
      "mitigations=off",
      "ignore_loglevel", -- debug for the 2026-08 lockups: every printk reaches netconsole; drop once solved
      "processor.max_cstate=1", -- 7900X SoC wake-fault mitigation until the CPU is swapped
      "usbcore.autosuspend=-1",
      "splash",
      "nvidia-drm.modeset=1",
      "nvidia-drm.fbdev=1",
    },

    packages = {
      "linux-cachyos",
      "linux-cachyos-nvidia-open",
      "nvidia-utils",
      "lib32-nvidia-utils",
      "amd-ucode",
      "acpid",
      "memtest86+-efi",
      "gpustat-git", -- check
      -- hosts/desktop/forge-tcmalloc.nix: Forge finds tcmalloc through plain ldconfig on Arch
      "gperftools",
      "bc",
    },

    -- hardware.nvidia.powerManagement: keep VRAM across S3, or the compositor resumes to black
    modprobe = { nvidia = "options nvidia NVreg_PreserveVideoMemoryAllocations=1\n" },
    services = {
      ["acpid.service"] = true,
      ["nvidia-suspend.service"] = true,
      ["nvidia-hibernate.service"] = true,
      ["nvidia-resume.service"] = true,
    },

    -- exit node: useRoutingFeatures = "server" plus the advertisement; approval is in the admin console
    sysctl = {
      ["net.ipv4.ip_forward"] = 1,
      ["net.ipv6.conf.all.forwarding"] = 1,
    },
    tailscale = { set_flags = { "--advertise-exit-node" } },

    -- eno1 and wlp8s0 share 192.168.0.0/24; wifi wins the route lookup, so strict rpfilter drops eno1's replies
    firewall = { check_reverse_path = "loose" },
  },
}
