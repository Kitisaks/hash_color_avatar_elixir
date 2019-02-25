# HashColorAvatar

This is very small library to generate SVG avatar


This is a small library to generate SVG initial avatar with unique-ish color based on string hash.

The primary feature is to generate on the fly SVG for default avatar. The user can get unique avatar (to certain degree) based on his name innitial and the unique color generated by hashing its name. Please be noted that of couse same name will resulting to the same image. And eventhough there are thousands of color exist, we choose to make the saturation fix so there can only be 359 possible color. 

Another function will be quite useful as well such as random_color/1, will give you nice pastel random color which you can use as background or anything.

set_color/2 can be used to make color by specifying the hue value. 

Function to Generate Initial from name, gen_initial/1 can also be used independently. 


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hash_color_avatar` to your list of dependencies in `mix.exs`:

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

