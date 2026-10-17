-- hosts/desktop/zapret.nix: DPI bypass for this machine only; the fixed-TTL strategy is tuned for this line.
local unit = archix.formats.systemd

local params = {
  "--filter-tcp=80,443",
  "--hostlist-domains=webshare.io",
  "--dpi-desync=fake,multidisorder",
  "--dpi-desync-split-pos=1,midsld",
  "--dpi-desync-fooling=md5sig",
  "--new",
  "--dpi-desync=multidisorder",
  "--dpi-desync-split-pos=1,midsld",
}

return {
  services = { ["zapret.service"] = true },
  -- replaces zapret-git's own zapret.service with the NixOS module's unit
  units = {
    ["zapret.service"] = unit {
      Unit = { Description = "DPI bypass service", After = "network.target" },
      Service = {
        ExecStart = "/usr/bin/nfqws --pidfile=/run/nfqws.pid " .. table.concat(params, " ") .. " --qnum=200",
        Type = "simple",
        PIDFile = "/run/nfqws.pid",
        Restart = "always",
        RuntimeMaxSec = "1h",
        DevicePolicy = "closed",
        KeyringMode = "private",
        PrivateTmp = true,
        PrivateMounts = true,
        ProtectHome = true,
        ProtectHostname = true,
        ProtectKernelModules = true,
        ProtectKernelTunables = true,
        ProtectSystem = "strict",
        ProtectProc = "invisible",
        RemoveIPC = true,
        RestrictNamespaces = true,
        RestrictRealtime = true,
        RestrictSUIDSGID = true,
        SystemCallArchitectures = "native",
      },
      Install = { WantedBy = "multi-user.target" },
    },
  },
  -- the module's ip46tables mangle rules: the first 6 packets of each HTTP(S) connection go to queue 200, skipping nfqws's own marked packets
  firewall = {
    extra_rules = [[
chain zapret {
  type filter hook postrouting priority mangle; policy accept;
  meta mark & 0x40000000 == 0 tcp dport { 80, 443 } ct original packets 1-6 queue num 200 bypass
}
]],
  },
}
