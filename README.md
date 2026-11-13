# float-telescope-preview.nvim

Open commands, files, LSP jumps, and Telescope selections in a centered
floating window (80% of the editor by default). The float closes when you
leave it.

## Requirements

- Neovim 0.10+
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for picker integration

## Installation

```lua
{
  'Foxinio/float-telescope-preview.nvim',
  dependencies = { 'nvim-telescope/telescope.nvim' },
  config = function()
    require('float-command').setup()
    require('telescope').load_extension('float_command')
  end,
}
```

## Usage

```lua
local float_command = require('float-command')

float_command.setup({
  border = 'rounded',
  width = 0.8,
  height = 0.8,
  -- zindex = 50,
  win_opts = {},
})

float_command.open('messages')
float_command.open_file('/path/to/file')
float_command.open_lsp(vim.lsp.buf.declaration)
float_command.open_telescope(require('telescope.builtin').lsp_definitions, { show_line = false })
```

`open_lsp(request)` calls an LSP location request such as
`vim.lsp.buf.definition` with an `on_list` handler: one location opens in the
float, several fill the quickfix list, none shows a message.
`open_telescope(picker, opts)` passes `opts` to the picker and keeps your
`attach_mappings`.

`:Float {command}` runs an Ex command in the float, for example
`:Float help nvim_open_win` or `:Float Man ls`.

The same functions are exported through
`require('telescope').extensions.float_command` after loading the extension.

Run the smoke check with:

```sh
make test
```
