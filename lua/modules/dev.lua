-- modules/nvim-lsp.nix: the LSP servers, formatters and linters the Neovim config expects.
return {
  packages = {
    "lua-language-server",
    "yaml-language-server",
    "dockerfile-language-server",
    "tailwindcss-language-server",
    "vscode-langservers-extracted", -- check
    "helm-ls",
    "just-lsp",
    "postgres-language-server-bin", -- check
    "gopls",
    "typescript-language-server",
    "vtsls",
    "prettier",
    "eslint_d",
    "stylua",
    "shfmt",
    "hadolint-bin",
    "kube-linter",
  },
  -- helm-ls 0.5.4's own tests fail against the 2026-10-17 Go toolchain; the binary itself builds fine.
  aur = { skip_check = { "helm-ls" } },
}
