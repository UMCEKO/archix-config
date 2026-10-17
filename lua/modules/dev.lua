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
}
