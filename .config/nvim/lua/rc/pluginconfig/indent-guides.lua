-- require('indent_guides').default_opts = {
--   indent_levels = 30;
--   indent_guide_size = 0;
--   indent_start_level = 1;
--   indent_space_guides = true;
--   indent_tab_guides = true;
--   indent_pretty_guides = true;
--   indent_soft_pattern = '\\s';
--   exclude_filetypes = {'help'}
-- }

-- vim.cmd('IndentGuidesDisable')
--require('indent_guides').indent_guides_disable()

require('indent_guides').setup({
})

vim.cmd('augroup vimrc_indent-guides')
vim.cmd('autocmd!')
vim.cmd('autocmd VimEnter * IndentGuidesDisable')
vim.cmd('augroup END')