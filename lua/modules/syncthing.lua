-- modules/syncthing.nix: Claude transcripts and instructions synced between the desktop and the laptop.
local devices = {
  desktop = "BNVEMQD-4LOXP2J-E2QNIV6-I7RPKXA-YKJVW5N-7NREBZU-5GYR644-R7W3YQ6",
  elitebook = "44QY3PG-JHY3EGY-DRQR2HF-DSE3QWI-724QB4H-AG2CNLM-AWEVBIG-NNV6WQA",
}
local home = "/home/umceko"

local peers, peer_refs = {}, {}
for name, id in pairs(devices) do
  if name ~= archix.hostname then
    peers[#peers + 1] = { deviceID = id, name = name }
    peer_refs[#peer_refs + 1] = { deviceID = id }
  end
end

local folders = {
  { id = "claude-transcripts", path = home .. "/.claude/projects", devices = peer_refs, fsWatcherDelayS = 5 },
  {
    id = "claude-config",
    path = home .. "/.claude-shared",
    devices = peer_refs,
    versioning = { type = "simple", params = { keep = "5" } },
  },
}

local posts = {}
for _, device in ipairs(peers) do
  posts[#posts + 1] = "api config/devices -X POST -d " .. archix.formats.shell_arg(archix.formats.json(device))
end
for _, folder in ipairs(folders) do
  posts[#posts + 1] = "api config/folders -X POST -d " .. archix.formats.shell_arg(archix.formats.json(folder))
end

return {
  packages = { "syncthing", "libxml2" },
  services = { ["syncthing@umceko.service"] = true },
  firewall = { allowed_tcp_ports = { 22000 }, allowed_udp_ports = { 22000, 21027 } },
  files = {
    -- configDir = ~/.config/syncthing, as on NixOS, so the copied key.pem keeps the device ID
    ["/etc/systemd/system/syncthing@umceko.service.d/10-home.conf"] = {
      text = "[Service]\nEnvironment=STHOMEDIR=" .. home .. "/.config/syncthing\n",
    },
  },
  -- Adds the peers and folders through the REST API like NixOS's syncthing-init; GUI-made ones are kept.
  hooks = {
    syncthing_init = {
      user = "umceko",
      run = [[
cfg="$HOME/.config/syncthing/config.xml"
[ -f "$cfg" ] || exit 0
key=$(xmllint --xpath 'string(configuration/gui/apikey)' "$cfg")
addr=$(xmllint --xpath 'string(configuration/gui/address)' "$cfg")
api() { path=$1; shift; curl -sSf -H "X-API-Key: $key" "http://$addr/rest/$path" "$@"; }
for _ in $(seq 30); do api system/ping >/dev/null 2>&1 && break; sleep 1; done
]] .. table.concat(posts, "\n") .. "\n" .. [[
if api config/restart-required | grep -q true; then api system/restart -X POST; fi
]],
    },
  },
}
