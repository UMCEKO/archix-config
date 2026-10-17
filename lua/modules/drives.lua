-- hosts/desktop/drives.nix: the data drives as mount units, sccache and Docker's data root on the secondary disk.
local unit = archix.formats.systemd

local function mount(what, where, fs, options, extra)
  local u = { Description = "Mount " .. where }
  for k, v in pairs(extra or {}) do u[k] = v end
  -- nofail: wanted, not required, by local-fs.target
  return unit {
    Unit = u,
    Mount = { What = what, Where = where, Type = fs, Options = options },
    Install = { WantedBy = "local-fs.target" },
  }
end

return {
  packages = { "ntfs-3g", "sccache" },

  units = {
    ["mnt-secondary.mount"] = mount("/dev/disk/by-uuid/13cf9875-1537-450d-8c74-08df12531862", "/mnt/secondary", "ext4", "defaults"),
    ["projects.mount"] = mount("/mnt/secondary/projects", "/projects", "none", "bind", { RequiresMountsFor = "/mnt/secondary" }),
    ["mnt-games.mount"] = mount("/dev/disk/by-uuid/057bff80-885c-4a90-b4f0-96c66220b32a", "/mnt/games", "ext4", "defaults"),
    ["mnt-mass\\x2dstorage.mount"] = mount("/dev/disk/by-uuid/d16defd8-27c2-491a-873c-987dde892838", "/mnt/mass-storage", "ext4", "defaults"),
  },
  services = {
    ["mnt-secondary.mount"] = true,
    ["projects.mount"] = true,
    ["mnt-games.mount"] = true,
    ["mnt-mass\\x2dstorage.mount"] = true,
  },

  -- env outranks cargo config, so this also beats a repo's `rustc-wrapper = ""`
  environment = {
    variables = {
      RUSTC_WRAPPER = "/usr/bin/sccache",
      SCCACHE_DIR = "/mnt/secondary/sccache",
      SCCACHE_CACHE_SIZE = "100G",
    },
  },

  files = {
    ["/etc/docker/daemon.json"] = { merge = { format = "json", values = { ["data-root"] = "/mnt/secondary/docker" } } },
    -- the mount dependency stops a nofail miss from filling root
    ["/etc/systemd/system/docker.service.d/10-data-root.conf"] = { text = "[Unit]\nRequiresMountsFor=/mnt/secondary/docker\n" },
  },
}
