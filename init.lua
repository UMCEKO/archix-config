return {
  imports = {
    "modules.repos",
    "modules.base",
    "modules.networking",
    "modules.desktop",
    "modules.dms",
    "modules.keyring",
    "modules.packages",
    "modules.dev",
    "modules.syncthing",
    "modules.home",
    "modules.claude",
    "modules.plasma",
    "modules.plasma_rc",
    "hosts." .. archix.hostname,
  },
}
