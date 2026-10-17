-- CachyOS's znver4 repos in its own pacman.conf order; drop this module if `archix init` already declared them.
local key = "882DCFE48E2051D48E2562ABF3B607488DB35A47"

local function repo(name, arch)
  return {
    name = name,
    servers = { "https://mirror.cachyos.org/repo/" .. arch .. "/$repo" },
    keys = { key },
    before_official = true,
  }
end

return {
  repos = { "core", "extra", "multilib" },
  custom_repos = {
    repo("cachyos-znver4", "x86_64_v4"),
    repo("cachyos-core-znver4", "x86_64_v4"),
    repo("cachyos-extra-znver4", "x86_64_v4"),
    repo("cachyos", "$arch"),
  },
}
