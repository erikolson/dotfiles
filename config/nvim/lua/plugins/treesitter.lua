-- ~/.config/nvim/lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  -- "master" is the frozen legacy branch that still ships nvim-treesitter.configs.
  -- The default branch is now "main", a rewrite without that module; moving to it
  -- needs a migration of the setup() call below.
  branch = "master",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "lua", "go", "typescript", "python", "bash", "json", "yaml", "toml" },
      highlight = { enable = true },
    })
  end,
}

