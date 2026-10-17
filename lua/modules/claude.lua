-- home/claude.nix: Claude Code's MCP servers, whose scripts live in the Syncthing folder.
return {
  packages = { "hypr-computer-mcp", "headless-computer-mcp", "nodejs" },
  home = {
    files = {
      [".claude/mcp"] = { link = "/home/umceko/.claude-shared/mcp" },
      -- ~/.claude.json also holds per-machine login and state, so only mcpServers is set
      [".claude.json"] = {
        merge = {
          format = "json",
          values = {
            mcpServers = {
              -- args and env are left out: an empty Lua table would merge in as a JSON object
              ["hypr-computer"] = { type = "stdio", command = "/usr/bin/hypr-computer-mcp" },
              ["headless-computer"] = { type = "stdio", command = "/usr/bin/headless-computer-mcp" },
              vortex = { type = "stdio", command = "/usr/bin/node", args = { "/home/umceko/.claude/mcp/vortex-tools.mjs" } },
            },
          },
        },
      },
    },
  },
}
