# float-telescope-preview.nvim

Open commands, files, LSP jumps, and Telescope selections in a fullscreen
floating window.

## Requirements

- Neovim
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
  zindex = nil,
  win_opts = {},
})

float_command.open('messages')
float_command.open_file('/path/to/file')
float_command.open_lsp(vim.lsp.buf.declaration)
float_command.open_telescope(require('telescope.builtin').lsp_definitions)
```

`:Float {command}` runs an Ex command in the float, for example
`:Float help nvim_open_win` or `:Float Man ls`.

The same functions are exported through
`require('telescope').extensions.float_command` after loading the extension.

Run the smoke check with:

```sh
nvim --headless -u NONE -l tests/smoke.lua
```
