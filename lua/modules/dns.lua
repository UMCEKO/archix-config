-- hosts/desktop/dns.nix: strict DNS-over-TLS to public resolvers; this box sits on one fixed line.
return {
  files = {
    ["/etc/systemd/resolved.conf.d/20-strict-dot.conf"] = {
      text = archix.formats.ini {
        Resolve = {
          DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net",
          DNSOverTLS = "true",
          FallbackDNS = "9.9.9.9#dns.quad9.net",
        },
      },
    },
    -- a link scope with servers beats the global one, so NM hands resolved none; [connection] ipv4.ignore-auto-dns is an unknown key there
    ["/etc/NetworkManager/conf.d/20-no-link-dns.conf"] = { text = "[main]\ndns=none\nsystemd-resolved=false\n" },
  },
}
