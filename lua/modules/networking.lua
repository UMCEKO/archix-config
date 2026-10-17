-- NetworkManager, resolved defaults, Tailscale, NetBird and the shared firewall from modules/common.nix.
local t = archix.types
local unit = archix.formats.systemd

local jumps = [[
#!/bin/sh
# tailscaled in nodivert mode makes its chains but no jumps; ours skip NetBird's wt0 (common.nix extraCommands).
for ipt in iptables ip6tables; do
  $ipt -D INPUT ! -i wt0 -j ts-input 2>/dev/null || true
  $ipt -D FORWARD -m comment --comment archix-ts -j ts-forward 2>/dev/null || true
  $ipt -t nat -D POSTROUTING -m comment --comment archix-ts -j ts-postrouting 2>/dev/null || true
  [ "$1" = stop ] && continue
  for chain in ts-input ts-forward; do $ipt -N "$chain" 2>/dev/null || true; done
  $ipt -t nat -N ts-postrouting 2>/dev/null || true
  $ipt -I INPUT 1 ! -i wt0 -j ts-input
  $ipt -I FORWARD 1 -m comment --comment archix-ts -j ts-forward
  $ipt -t nat -I POSTROUTING 1 -m comment --comment archix-ts -j ts-postrouting
done
]]

return {
  options = {
    tailscale = {
      set_flags = archix.option {
        type = t.list_of(t.str),
        default = {},
        description = "Flags `tailscale set` applies on every switch, like NixOS's services.tailscale.extraSetFlags.",
      },
    },
  },
  config = function(cfg)
    local result = {
      packages = { "networkmanager", "tailscale", "netbird", "iptables" },
      services = {
        ["NetworkManager.service"] = true,
        ["systemd-resolved.service"] = true,
        ["tailscaled.service"] = true,
        ["ts-netfilter-jumps.service"] = true,
        ["netbird@default.service"] = true,
      },
      tailscale = { set_flags = { "--netfilter-mode=nodivert", "--operator=umceko" } },
      firewall = {
        enable = true,
        trusted_interfaces = { "tailscale0", "wt0" },
        allowed_udp_ports = { 41641, 51820 },
        allowed_tcp_port_ranges = { { from = 1714, to = 1764 } },
        allowed_udp_port_ranges = { { from = 1714, to = 1764 } },
      },
      files = {
        ["/etc/resolv.conf"] = { link = "/run/systemd/resolve/stub-resolv.conf" },
        ["/etc/NetworkManager/conf.d/10-resolved.conf"] = { text = "[main]\ndns=systemd-resolved\n" },
        ["/etc/systemd/resolved.conf.d/10-defaults.conf"] = {
          text = "[Resolve]\nDNSSEC=false\nDNSOverTLS=opportunistic\nFallbackDNS=9.9.9.9\n",
        },
        ["/usr/local/libexec/ts-netfilter-jumps"] = { text = jumps, mode = "0755" },
        -- the NixOS module only ever sets these two keys; netbird keeps the rest of its state in the same file
        ["/etc/netbird/config.json"] = { merge = { format = "json", values = { DisableDNS = true, DisableClientRoutes = false } } },
      },
      units = {
        ["ts-netfilter-jumps.service"] = unit {
          Unit = { Description = "Jumps into tailscaled's nodivert chains", After = "tailscaled.service", Wants = "tailscaled.service" },
          Service = {
            Type = "oneshot",
            RemainAfterExit = true,
            ExecStart = "/usr/local/libexec/ts-netfilter-jumps start",
            ExecStop = "/usr/local/libexec/ts-netfilter-jumps stop",
          },
          Install = { WantedBy = "multi-user.target" },
        },
      },
    }
    local flags = {}
    for i, flag in ipairs(cfg.tailscale.set_flags) do flags[i] = archix.formats.shell_arg(flag) end
    if #flags > 0 then
      result.hooks = {
        tailscale_set = { run = "tailscale set " .. table.concat(flags, " ") .. "\n" },
      }
    end
    return result
  end,
}
