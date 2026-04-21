# nvim-flashcard

A Neovim plugin for learning with flashcards, backed by SM-2 spaced repetition.
Decks are plain markdown files you edit in the same editor you study in.

## Features

- Markdown decks — one file per deck, `---` between cards, `?` between front and back
- SM-2 scheduling with the familiar Again / Hard / Good / Easy ratings
- Centered floating-window review UI
- Telescope-backed deck picker (falls back to `vim.ui.select`)
- Per-deck JSON sidecar for scheduling state; your markdown is never modified

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "dautroc/nvim-flashcard",
  opts = {},  -- see Configuration below
  cmd = "Flashcard",
}
```

Telescope is optional; without it, the picker uses `vim.ui.select`.

## Configuration

```lua
require("flashcard").setup({
  decks_dir = vim.fn.stdpath("data") .. "/flashcard/decks",
  new_cards_per_day = 20,
  keymaps = {
    reveal = "<Space>",
    again  = "1",
    hard   = "2",
    good   = "3",
    easy   = "4",
    quit   = "q",
  },
  window = { width = 0.5, height = 0.4, border = "rounded" },
})
```

## Usage

1. Create a deck file at `<decks_dir>/<name>.md`:

   ````markdown
   # Geography (title is ignored)

   What is the capital of France?
   ?
   Paris.

   ---

   What is the largest ocean?
   ?
   The Pacific.
   ````

2. Run `:Flashcard` to pick a deck, or `:Flashcard geography` to skip the picker.

3. Review:
   - `<Space>` reveals the back
   - `1` / `2` / `3` / `4` rates the card (Again / Hard / Good / Easy)
   - `q` closes the session

## Deck format

- Each file is one deck.
- Cards are separated by a standalone `---` line (markdown horizontal rule).
- Within a card, a standalone `?` line separates the front from the back.
- Content before the first card (e.g. a `# Title`) is ignored.
- Multi-line fronts and backs are supported; leading/trailing whitespace is trimmed.

## State

For each deck `foo.md`, scheduling lives in a sibling `foo.state.json` file —
card ease, interval, reps, and next-due date. Writes are atomic (`.tmp` + rename).

## Development

```bash
make test     # run plenary/busted specs
make lint     # stylua --check
make format   # stylua in-place
```

## License

MIT
