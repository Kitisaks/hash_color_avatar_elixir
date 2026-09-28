# HashColorAvatar

Small Elixir library to generate deterministic SVG initial avatars from a string.

The hash palette is tuned for the Tatex admin: white initials stay at WCAG AA, and each disc stays visible on working paper (`#f4f4f6`) and dark chrome (`#262830`). Output is flat SVG (no filters, no gradients) so a member list can render dozens of them without extra paint cost. Initials use Inter, then the system UI stack, matching the Tatex type ramp.

## Features

- Deterministic initials: `get_initial/1` turns a name into up to 2 characters (first + last).
- Twelve-swatch hash palette. The same name always picks the same color.
- Flat SVG:
  - `:minimal` is a solid disc (the variant Tatex embeds at 32, 40, 48, 120, and 160px)
  - `:modern` adds a hairline rim and still skips drop shadows and gradients
  - Uppercase initials are optically centered
  - Text color is chosen for contrast when `:text_color` is omitted
- Utility functions:
  - `random_color/1` (HSV -> RGB -> hex)
  - `set_color/2` (convert a hue value to hex)

## Installation

If [available in Hex](https://hex.pm/docs/publish), add `hash_color_avatar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hash_color_avatar, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hash_color_avatar](https://hexdocs.pm/hash_color_avatar).

## Usage

### `get_initial/1`

Extracts up to 2 initials from a string. Non-letter characters are removed.

```elixir
iex> HashColorAvatar.get_initial("guruh soekarno putra")
"GP"
```

If the input contains no usable characters, it returns:

```elixir
iex> HashColorAvatar.get_initial("")
"VK"
```

### `gen_avatar/2`

Generates an SVG avatar containing the initials and a background. Returns a **binary** string.

```elixir
svg = HashColorAvatar.gen_avatar("Marlyn Monroe")
```

Options:

- `:color`
  - `nil` (default): pick a background from the contrast-safe hash palette
  - `"grey"`: solid `#c3c3c3`
  - `"black"`: solid `#000000`
  - `"random"`: random HSV-derived solid color
  - any other string: treated as a CSS/hex color (used as-is)
- `:style`
  - default `:modern`: solid fill plus a hairline rim
  - `:minimal`: solid fill only (what Tatex uses in lists and the header)
- `:shape`
  - default: `:circle`
  - `:rect`: rounded rectangle background
- `:size`
  - positive integer SVG size in pixels (default `100`)
- `:text_color`
  - when omitted, initials color is chosen automatically for contrast
  - pass `"white"`, `"#1e293b"`, etc. to override
- `:font_family`
  - default: `Inter, ui-sans-serif, system-ui, sans-serif`

Examples:

```elixir
iex> HashColorAvatar.gen_avatar("Marlyn Monroe", style: :minimal) |> String.contains?(">MM</text>")
true

iex> HashColorAvatar.gen_avatar("Sagit Putri Lestari Harum Mewangi", shape: :rect) |> String.contains?("<rect")
true
```

### `random_color/1`

Generates a random hex color string using HSV with defaults:
- saturation: `50`
- value: `90`

Options:
- `:saturation`
- `:value`

```elixir
iex> HashColorAvatar.random_color(saturation: 70, value: 100)
"#RRGGBB"
```

### `set_color/2`

Converts a hue value (`0..359` is typical; values are normalized) to a hex color string.

Options:
- `:saturation` (default `50`)
- `:value` (default `90`)

```elixir
iex> HashColorAvatar.set_color(12)
"#E58972"
```
