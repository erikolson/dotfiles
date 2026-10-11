-- ~/.config/nvim/lua/config/keymaps.lua
vim.g.mapleader = " "

--vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, {})
--vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, {})
--vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, {})
--vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, {})

vim.keymap.set("n", "<leader>ll", "<cmd>Lazy<CR>", { desc = "Open Lazy UI" })
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Markdown Preview" })
vim.keymap.set("n", "<leader>-", "<cmd>Ex<CR>", { desc = "Explore the directory" })

-- LSP (the built-in defaults K, grr, grn, gra, <C-]> still work; these are the discoverable versions)
vim.keymap.set("n", "<leader>ld", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>lr", vim.lsp.buf.references, { desc = "List references" })
vim.keymap.set("n", "<leader>lh", vim.lsp.buf.hover, { desc = "Hover docs" })
vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code action" })
vim.keymap.set("n", "<leader>le", vim.diagnostic.open_float, { desc = "Explain diagnostics on this line" })
