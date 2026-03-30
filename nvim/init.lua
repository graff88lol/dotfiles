-- init.lua - Main Neovim configuration

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.timeoutlen = 300
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.cursorline = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.swapfile = false
vim.opt.backup = false

-- Undo settings
local undodir = os.getenv("HOME") .. "/.local/share/nvim/undo"
vim.fn.mkdir(undodir, "p")
vim.opt.undodir = undodir
vim.opt.undofile = true
vim.opt.undolevels = 10000

-- Clipboard integration with Wayland
if vim.fn.has("wsl") == 0 then
    vim.g.clipboard = {
        name = "wl-clipboard",
        copy = {
            ["+"] = "wl-copy",
            ["*"] = "wl-copy",
        },
        paste = {
            ["+"] = "wl-paste",
            ["*"] = "wl-paste",
        },
        cache_enabled = true,
    }
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
    -- Theme
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("tokyonight-night")
        end,
    },
    
    -- File explorer
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                view = {
                    width = 30,
                    side = "left",
                },
                renderer = {
                    icons = {
                        show = {
                            git = true,
                            folder = true,
                            file = true,
                        },
                    },
                },
                filters = {
                    dotfiles = false,
                },
            })
        end,
    },
    
    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "tokyonight",
                    section_separators = "",
                    component_separators = "",
                },
            })
        end,
    },
    
    -- Buffer line
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("bufferline").setup({
                options = {
                    mode = "buffers",
                    numbers = "none",
                    close_command = "bdelete! %d",
                    right_mouse_command = "bdelete! %d",
                    left_mouse_command = "buffer %d",
                    diagnostics = "nvim_lsp",
                    always_show_bufferline = true,
                },
            })
        end,
    },
    
    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    file_ignore_patterns = {
                        "node_modules",
                        ".git",
                        "__pycache__",
                    },
                },
            })
        end,
    },
    
    -- Treesitter (syntax highlighting)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = "VeryLazy",  -- Load after Neovim starts
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "lua", "vim", "vimdoc", "query",
                    "javascript", "typescript", "html", "css",
                    "python", "go", "rust", "nix", "bash",
                },
                auto_install = true,
                highlight = {
                    enable = true,
                },
                indent = {
                    enable = true,
                },
            })
        end,
    },    
    -- LSP Configuration (Updated for Neovim 0.11+)
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "nixd",
                    "pyright",
                    "ts_ls",
                },
                automatic_installation = true,
            })
            
            -- New vim.lsp.config API
            vim.lsp.config("lua_ls", {
                cmd = { "lua-language-server" },
                filetypes = { "lua" },
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
            
            vim.lsp.config("nixd", {
                cmd = { "nixd" },
                filetypes = { "nix" },
            })
            
            vim.lsp.config("pyright", {
                cmd = { "pyright-langserver", "--stdio" },
                filetypes = { "python" },
            })
            
            vim.lsp.config("ts_ls", {
                cmd = { "typescript-language-server", "--stdio" },
                filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
            })
            
            -- Enable LSP servers
            vim.lsp.enable("lua_ls", "nixd", "pyright", "ts_ls")
            
            -- Keymaps for LSP
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    local bufopts = { noremap = true, silent = true, buffer = ev.buf }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
                    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, bufopts)
                    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, bufopts)
                    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, bufopts)
                end,
            })
        end,
    },
    
    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            
            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                }, {
                    { name = "buffer" },
                }),
            })
        end,
    },
    
    -- Git
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup()
        end,
    },
    
    -- Comment
    {
        "numToStr/Comment.nvim",
        config = function()
            require("Comment").setup()
        end,
    },
})

-- Key mappings
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find buffers" })
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>", { desc = "Close window" })
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Terminal
vim.keymap.set("n", "<leader>t", "<cmd>split term://$SHELL<CR>", { desc = "Open terminal in split" })
vim.keymap.set("n", "<leader>vt", "<cmd>vsplit term://$SHELL<CR>", { desc = "Open terminal in vertical split" })

-- Clear search highlight
vim.keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search highlight" })

print("Neovim loaded successfully! 🚀")
