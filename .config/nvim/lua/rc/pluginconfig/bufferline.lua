vim.cmd [[hi TabLineSel guibg=#ddc7a1]]

require('bufferline').setup {
  options = {
    numbers = "ordinal",
    number_style = {"none", "subscript"},
    -- NOTE: this plugin is designed with this icon in mind,
    -- and so changing this is NOT recommended, this is intended
    -- as an escape hatch for people who cannot bear it for whatever reason
    -- indicator_icon = '▎',
    -- buffer_close_icon = '',
    -- modified_icon = '●',
    -- close_icon = '',
    -- left_trunc_marker = '',
    -- right_trunc_marker = '',
    -- max_name_length = 18,
    -- max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
    -- tab_size = 18,
    -- diagnostics = false,
    -- diagnostics_indicator = function(count, level, diagnostics_dict, context)
    --   return "(" .. count .. ")"
    -- end,
    -- NOTE: this will be called a lot so don't do any heavy processing here
    custom_filter = function(buf_number)
      -- filter out filetypes you don't want to see
      if vim.bo[buf_number].filetype == "qf" then
        return false
      end
      if vim.bo[buf_number].buftype == "terminal" then
        return false
      end
      -- -- filter out by buffer name
      if vim.fn.bufname(buf_number) == '' or vim.fn.bufname(buf_number) == '[No Name]' then
        return false
      end
      -- -- filter out based on arbitrary rules
      -- -- e.g. filter out vim wiki buffer from tabline in your work repo
      -- if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
      --   return true
      -- end
      return true
    end,
    -- offsets = {
    --   {filetype = "NvimTree", text = "File Explorer", text_align = "left" | "center" | "right"}
    -- },
    -- show_buffer_icons = true,
    show_buffer_close_icons = false,
    show_close_icon = false,
    -- show_tab_indicators = true
    -- persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
    -- can also be a table containing 2 custom separators
    -- [focused and unfocused]. eg: { '|', '|' }
    -- separator_style = "thick",
    enforce_regular_tabs = true
    -- always_show_bufferline = true
    -- sort_by = 'relative_directory'
  }
}
vim.api
    .nvim_set_keymap('n', '<Leader>b', '<Cmd>BufferLinePick<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'H', '<Cmd>BufferLineCyclePrev<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', 'L', '<Cmd>BufferLineCycleNext<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '@', '<Cmd>BufferLineMovePrev<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '#', '<Cmd>BufferLineMoveNext<CR>', {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-S-F2>', '<Cmd>BufferLineMovePrev<CR>',
                        {noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-S-F3>', '<Cmd>BufferLineMoveNext<CR>',
                        {noremap = true, silent = true})