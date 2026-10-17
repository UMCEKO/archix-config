-- modules/common.nix minus networking and the desktop session: locale, users, sudo, sound, printing, docker.
local unit = archix.formats.systemd

return {
  mutable_files = false,
  timezone = "Europe/Istanbul",
  locales = { "en_US.UTF-8" },
  keymap = "us",

  -- lanzaboote's configurationLimit; boot.secure_boot stays automatic, signing once /var/lib/sbctl has keys.
  boot = { loader = "systemd-boot", entries = 10 },

  packages = {
    "base",
    "linux-firmware",
    "btrfs-progs",
    "sudo",
    "sbctl",
    "pipewire",
    "pipewire-alsa",
    "pipewire-pulse",
    "wireplumber",
    "lib32-pipewire",
    "rtkit",
    "cups",
    "docker",
    "docker-buildx",
    "neovim",
    "claude-code",
    "brave-bin",
    "firefox",
    "zapret-git",
    "fuse2",
    "kate",
  },

  services = {
    ["cups.service"] = true,
    ["docker.service"] = true,
    ["docker-prune.timer"] = true,
  },

  users = {
    umceko = {
      description = "Umut Cevdet Kocak",
      groups = { "networkmanager", "wheel", "docker", "video", "render", "storage", "lp", "scanner", "input" },
      shell = "/usr/bin/zsh",
    },
  },
  groups = { networkmanager = { system = true } },

  files = {
    ["/etc/sudoers.d/10-wheel"] = { text = "%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n", mode = "0440" },
    ["/etc/docker/daemon.json"] = {
      merge = {
        format = "json",
        values = {
          ["default-address-pools"] = { { base = "10.210.0.0/16", size = 24 } },
          builder = { gc = { enabled = true, defaultKeepStorage = "20GB" } },
        },
      },
    },
  },

  units = {
    ["docker-prune.service"] = unit {
      Unit = { Description = "Prune docker resources", After = "docker.service", Requires = "docker.service" },
      Service = { Type = "oneshot", ExecStart = "/usr/bin/docker system prune -f --filter=until=168h" },
    },
    ["docker-prune.timer"] = unit {
      Timer = { OnCalendar = "weekly", Persistent = true },
      Install = { WantedBy = "timers.target" },
    },
  },

  environment = {
    variables = { EDITOR = "nvim", BROWSER = "brave" },
    shell_aliases = { nrs = "sudo archix switch" },
  },
}
