# pele.nvim

Render Mermaid fences inline in Neovim with [Pele](https://github.com/obsidianmd/pele). Source stays editable; previews appear below the diagram source with virtual padding. Rendering runs in a separate Node process and refreshes after edits.

## Requirements

- Neovim 0.10+ and Node.js 22+
- [image.nvim](https://github.com/3rd/image.nvim), configured with a supported graphics backend
- ImageMagick for image.nvim's default `magick_cli` processor
- A compatible terminal (Kitty recommended); ordinary text-only terminals cannot display these previews

## Installation with lazy.nvim

Add this plugin specification to your lazy.nvim configuration:

```lua
{
  'javelin-sh/pele.nvim',
  build = 'npm ci',
  dependencies = {
    {
      '3rd/image.nvim',
      build = false,
      opts = {
        backend = 'kitty',
        processor = 'magick_cli',
      },
    },
  },
  config = function()
    require('pele').setup({
      debounce = 300,
      width = 80, -- maximum preview width in terminal cells
      height = 24, -- maximum preview height in terminal cells
      filetypes = { 'markdown' },
      node = 'node',
    })
  end,
}
```

Open `examples/diagrams.md`. Use `:PeleRender` to refresh and `:PeleToggle` to hide/show previews. Previews hide during Insert mode to keep autocomplete menus readable and return after you leave Insert mode. No Tree-sitter parser is required. Top-level backtick and tilde fences are supported; blockquote/list-nested fences are not currently parsed.

## Rendering

Pele produces SVG, CSS variable defaults are resolved for resvg, and `@resvg/resvg-js` rasterizes the result to PNG. image.nvim handles terminal drawing, scrolling, and virtual padding. Diagrams inherit Neovim highlight colors and refresh automatically on `ColorScheme` and `background` changes. Colors come from Normal, NormalFloat, CursorLine, FloatBorder, Comment, and syntax highlight groups. When Normal has no background (transparent themes), a light/dark fallback is used. After manual `:highlight` edits, run `:PeleRender`. Rendered PNGs are cached by diagram source and theme for the Neovim session, and removed on exit. Buffer switches, toggling previews, and leaving Insert mode reuse cached diagrams. Concurrent requests for the same diagram share one render. No diagram content is sent over the network.

Each diagram has a 100 KB source limit and a 15-second process timeout. Parse failures appear as Neovim warnings. Only changed diagrams or palettes need another Pele render. The session cache retains previously rendered variants until exit; very large editing sessions can use additional temporary disk space.

## Development

```sh
npm ci
npm test
```

Tests cover actual Pele-to-PNG rendering, invalid syntax, Markdown fence selection, and a headless Neovim render/toggle lifecycle with a mocked image.nvim display API. Actual terminal graphics require a manual check in a configured terminal; the automated tests do not verify terminal pixels.
