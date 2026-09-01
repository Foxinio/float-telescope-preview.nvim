# float-command.nvim

Open commands, files, LSP jumps, and Telescope selections in an Overseer-style
fullscreen floating window.

## Requirements

- Neovim
- [overseer.nvim](https://github.com/stevearc/overseer.nvim)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for picker integration

## Installation

```lua
{
  dir = '/path/to/float-command.nvim',
  dependencies = {
    'stevearc/overseer.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('telescope').load_extension('float_command')
  end,
}
```

## Usage

```lua
local float_command = require('float-command')

float_command.open('messages')
float_command.open_file('/path/to/file')
float_command.open_lsp(vim.lsp.buf.declaration)
float_command.open_telescope(require('telescope.builtin').lsp_definitions)
```

The same functions are exported through
`require('telescope').extensions.float_command` after loading the extension.

Run the smoke check with:

```sh
nvim --headless -u NONE -l tests/smoke.lua
```
