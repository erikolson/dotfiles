-- ~/.config/nvim/lua/plugins/lsp.lua
-- Uses the new Neovim 0.11+ API: vim.lsp.config() + vim.lsp.enable()
-- Falls back to lspconfig.setup() automatically on older versions.

return {
  "neovim/nvim-lspconfig",
  config = function()
    -- capabilities (so LSP integrates with nvim-cmp if present)
    local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = ok_cmp and cmp_nvim_lsp.default_capabilities()
      or vim.lsp.protocol.make_client_capabilities()

    -- Compat shim: prefer the new API, fall back to lspconfig.<server>.setup
    local use_new = vim.lsp and vim.lsp.config
    local setup = use_new and function(server, opts)
        vim.lsp.config(server, opts)
        vim.lsp.enable(server)
      end
      or function(server, opts) require("lspconfig")[server].setup(opts) end

    -- Only set up servers whose binary is on PATH, so missing ones don't error
    local function configure(server, bin, opts)
      if vim.fn.executable(bin) == 1 then setup(server, opts) end
    end

    -- ────────────────────────────────────────────────────────────────────────────
    -- Lua (Neovim config)
    configure("lua_ls", "lua-language-server", {
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = { version = "LuaJIT" },
          diagnostics = { globals = { "vim" } },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = { enable = false },
        },
      },
    })

    -- Go
    configure("gopls", "gopls", {
      capabilities = capabilities,
      -- settings = { gopls = { hints = { assignVariableTypes = true } } },
    })

    -- Rust
    configure("rust_analyzer", "rust-analyzer", {
      capabilities = capabilities,
      -- settings = { ["rust-analyzer"] = { cargo = { allFeatures = true } } },
    })

    -- Zig
    configure("zls", "zls", {
      capabilities = capabilities,
    })

    -- TypeScript / JavaScript (was 'tsserver')
    configure("ts_ls", "typescript-language-server", {
      capabilities = capabilities,
      -- settings = {
      --   typescript = { inlayHints = { includeInlayParameterNameHints = "all" } },
      --   javascript = { inlayHints = { includeInlayParameterNameHints = "all" } },
      -- },
    })

    -- Python
    configure("pyright", "pyright-langserver", {
      capabilities = capabilities,
    })

    -- Nix
    configure("nil_ls", "nil", {
      capabilities = capabilities,
    })

    -- C/C++  (requires 'clangd' on PATH; add pkgs.clang-tools in your flake)
    configure("clangd", "clangd", {
      capabilities = capabilities,
    })
  end,
}

