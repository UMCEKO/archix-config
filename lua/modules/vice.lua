-- modules/vice.nix ported as a typed module: the Vice instant-replay clipper and its session daemon.
local t = archix.types

return {
  options = {
    vice = {
      enable = archix.option { type = t.bool, default = false, description = "The Vice game clip recorder." },
      package = archix.option { type = t.str, default = "vice-clipper", description = "The package that provides vice." },
      auto_start = archix.option {
        type = t.bool,
        default = true,
        description = "Run the clipping daemon for the whole graphical session.",
      },
    },
  },
  config = function(cfg)
    local vice = cfg.vice
    if not vice.enable then return {} end
    local sections = {
      Unit = {
        Description = "Vice game clip recorder daemon",
        After = "graphical-session.target",
        StartLimitIntervalSec = 60,
        StartLimitBurst = 3,
      },
      Service = {
        Type = "simple",
        ExecStart = "/usr/bin/vice start --no-open-ui",
        Restart = "on-failure",
        RestartSec = 3,
        PassEnvironment = "WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS XDG_SESSION_TYPE XDG_CURRENT_DESKTOP",
      },
    }
    if vice.auto_start then sections.Install = { WantedBy = { "graphical-session.target", "default.target" } } end
    return {
      packages = { vice.package, "gpu-screen-recorder" },
      user_units = { ["vice.service"] = archix.formats.systemd(sections) },
      user_services = { ["vice.service"] = vice.auto_start },
      hooks = {
        -- programs.gpu-screen-recorder's capability, so gsr-kms-server doesn't go through pkexec on every restart
        gsr_kms_server_cap = {
          run = "getcap /usr/bin/gsr-kms-server | grep -q cap_sys_admin || setcap cap_sys_admin+ep /usr/bin/gsr-kms-server\n",
        },
      },
    }
  end,
}
