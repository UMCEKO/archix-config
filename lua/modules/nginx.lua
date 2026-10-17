-- hosts/desktop/nginx.nix: reverse proxy for the *.umceko.com dev hosts, with NixOS's recommended proxy and optimisation settings.
local vhosts = {
  { "dev.umceko.com", 3000 },
  { "frontend.umceko.com", 3000 },
  { "backend.umceko.com", 3001 },
  { "test.umceko.com", 3001 },
  { "gateway.umceko.com", 3002 },
  { "kabinet.umceko.com", 3100 },
  { "browser.umceko.com", 6901 },
  { "cadrantech.umceko.com", 8080 },
  { "a1111.umceko.com", 7860, "client_max_body_size 100M;" },
}

-- a location's own proxy_set_header drops every inherited one, so the recommended headers are repeated with the websocket ones
local headers = [[
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Server $hostname;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
]]

local servers = {}
for _, v in ipairs(vhosts) do
  servers[#servers + 1] = string.format([[
    server {
        listen 80;
        listen [::]:80;
        server_name %s;
        location / {
            proxy_pass http://127.0.0.1:%d;
            proxy_http_version 1.1;
%s        }
        proxy_read_timeout 86400s;
        %s
    }
]], v[1], v[2], headers, v[3] or "")
end

local conf = [[
user http;
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;
    types_hash_max_size 4096;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    client_max_body_size 20M;

    proxy_redirect off;
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    proxy_http_version 1.1;
    proxy_set_header "Connection" "";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Server $hostname;

    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        location / {
            return 404;
        }
    }

]] .. table.concat(servers, "\n") .. "}\n"

return {
  packages = { "nginx" },
  services = { ["nginx.service"] = true },
  files = { ["/etc/nginx/nginx.conf"] = { text = conf } },
  firewall = { allowed_tcp_ports = { 80 } },
}
