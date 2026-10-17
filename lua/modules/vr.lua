-- hosts/desktop/vr.nix plus the VR packages from hosts/desktop/packages.nix: WiVRn, ALVR, WayVR, xrizer, OpenComposite.
return {
  packages = {
    "wivrn-server",
    "wivrn-dashboard",
    "alvr-bin", -- the source build fails against current PipeWire (libspa 0.8)
    "wayvr",
    "xrizer",
    "opencomposite-git",
    "umu-launcher",
    "bs-manager-bin",
  },
  -- services.wivrn.openFirewall; autoStart was off, so the server isn't enabled
  firewall = { allowed_tcp_ports = { 9757 }, allowed_udp_ports = { 9757 } },
}
