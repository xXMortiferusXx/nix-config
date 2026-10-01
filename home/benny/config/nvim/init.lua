-- 1. Plugin-Manager (Paq) - :PaqInstall Befehl ausführen damit die LUA geht 
local install_path = vim.fn.stdpath('data') .. '/site/pack/paqs/start/paq-nvim'
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system({'git', 'clone', '--depth=1', 'https://github.com/savq/paq-nvim.git', install_path})
end

require "paq" {
  "savq/paq-nvim";
  "nvim-lualine/lualine.nvim";
  "nvim-tree/nvim-web-devicons";
  "folke/tokyonight.nvim";
  "lewis6991/gitsigns.nvim";
  "windwp/nvim-autopairs";
}

-- 2. Modernes Interface
vim.opt.termguicolors = true
vim.opt.number = true           -- Zeilennummern AN
vim.opt.relativenumber = true   -- Relative Nummern AN
vim.opt.laststatus = 3          -- DIE moderne Line (global)
vim.opt.showmode = false        -- Kein hässliches -- INSERT -- mehr
vim.opt.cursorline = true       -- Aktuelle Zeile markieren
vim.opt.fillchars = { eob = " " } 

-- 3. Theme & Transparenz
require("tokyonight").setup({ style = "storm", transparent = true })
vim.cmd[[colorscheme tokyonight]]

-- Der Fix, damit die Nummern und der Hintergrund perfekt sind
local function theme_fix()
  local hls = { "Normal", "NormalFloat", "NormalNC", "SignColumn", "LineNr", "CursorLineNr" }
  for _, hl in ipairs(hls) do
    vim.api.nvim_set_hl(0, hl, { bg = "none" })
  end
  vim.api.nvim_set_hl(0, "LineNr", { fg = "#565f89" }) -- Dezente Nummern
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ff9e64", bold = true }) -- Helle aktuelle Nummer
end

-- 4. Moderne Line (Lualine)
require('lualine').setup {
  options = {
    theme = 'tokyonight',
    globalstatus = true,
    section_separators = { left = '', right = '' },
    component_separators = '',
  },
  sections = {
    lualine_a = {{ 'mode', separator = { left = '' }, right_padding = 2 }},
    lualine_z = {{ 'location', separator = { right = '' }, left_padding = 2 }},
  }
}

-- 5. Helfer
require('nvim-autopairs').setup({})
require('gitsigns').setup()
theme_fix()
