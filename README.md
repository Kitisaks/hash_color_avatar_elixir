# HashColorAvatar

Small Elixir library to generate deterministic, unique-ish SVG avatars (initials) from a string.

## Features

- Deterministic initials: `get_initial/1` turns a name into up to 2 characters (first + last).
- Deterministic color: when you don’t pass `:color`, the background is derived from the input string hash.
- Optional modern SVG styling (set `style: :modern`):
  - Linear gradient background
  - Subtle drop shadow
  - Rounded highlight overlay
  - Subtle ring stroke
- Utility functions:
  - `random_color/1` (HSV -> RGB -> hex)
  - `set_color/2` (convert a hue value to hex)

## Installation

If [available in Hex](https://hex.pm/docs/publish), add `hash_color_avatar` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hash_color_avatar, "~> 0.1.0"}
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

Generates an SVG avatar containing the initials and a background (minimal by default).

Important: `gen_avatar/2` returns a **charlist** containing the SVG. If you need a binary string:

```elixir
svg = HashColorAvatar.gen_avatar("Marlyn Monroe") |> to_string()
```

Options:

- `:color`
  - `nil` (default): derive a background color from the name hash
  - `"grey"`: solid `#c3c3c3`
  - `"black"`: solid `#000000`
  - `"random"`: random HSV-derived solid color
  - any other string: treated as a CSS/hex color (used as-is)
- `:style`
  - default `:minimal`: solid background (no gradients, no shadow filters) for easy icon embedding
  - `:modern`: gradient background + subtle drop shadow + highlight + ring
- `:shape`
  - default: `"circle"`
  - `"rect"`: rounded rectangle background (ring appears in `style: :modern`)
- `:size`
  - positive integer SVG size in pixels (default `100`)
- `:text_color`
  - default: `"white"` (customize the initials color)
- `:font_family`
  - default: a system UI font stack (customize the initials font family)

Examples:

```elixir
iex> HashColorAvatar.gen_avatar("Marlyn Monroe") |> to_string() |> String.contains?("<svg")
true

iex> HashColorAvatar.gen_avatar("Sagit Putri Lestari Harum Mewangi", shape: "rect") |> to_string() |> String.contains?("<rect")
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

