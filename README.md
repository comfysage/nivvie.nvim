# nivvie :seedling:

tiny neovim session keeper, keeping your place safe

## :herb: what it does

nivvie remembers where you left off and restores it when you return (session
handling). it keeps sessions stored safely and lets you call on them whenever
you need, without clutter or extra ritual.

## why nivvie

there are larger session managers with more features. nivvie is a small and
quiet companion, meant for when you want something clean, simple, and reliable.

## :sparkles: features

- automatic save and restore (no extra steps)
- manual save, load, and delete commands (direct control)
- minimal configuration (defaults just work)
- lightweight and unobtrusive (stays out of the way)

## :potted_plant: installation

add nivvie with your favourite plugin manager.

###### `vim.pack`

```lua
vim.pack.add({ "comfysage/nivvie.nvim" })
```

###### `lazy.nvim`

```lua
{
  "comfysage/nivvie.nvim",
  lazy = false, -- nivvie takes care of its own lazy loading
  config = function()
    require("nivvie").setup() -- not necessary to call
  end
}
```

## :rose: usage

sessions are saved automatically when you quit neovim and restored when you open it again. you can also manage sessions yourself:

```
:Nivvie save [name]   " save the current session for the current directory or with a custom name
:Nivvie load [name]   " load session for the current directory or with a custom name
:Nivvie delete [name] " delete session for the current directory or with a custom name
```

you may also map keys to these commands:

```lua
vim.keymap.set("n", "<leader>ss", ":NivvieSave<CR>")
vim.keymap.set("n", "<leader>sl", ":NivvieLoad<CR>")
```

## :wilted_flower: configuration

nivvie works without configuration (zero setup). you can still adjust its behavior:

```lua
require("nivvie").setup({
  -- where sessions are stored
  session_dir = vim.fn.stdpath("state") .. "/sessions",
  -- save on exit
  autosave = true,
  -- load on start
  autorestore = true,
})
```
