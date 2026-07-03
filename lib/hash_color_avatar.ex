defmodule HashColorAvatar do
  @moduledoc """
  Generate deterministic SVG initial avatars with hash-derived pastel colors.

  Colors are derived from the input string so the same name always produces the
  same avatar. `random_color/1` and `set_color/2` are available for ad-hoc colors.

  `gen_avatar/2` returns an SVG **binary** string.
  """

  @default_shape :circle
  @default_size 100
  @default_style :modern
  @default_saturation 50
  @default_value 90
  @font_family "ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif"
  @initial_fallback "VK"
  @max_hue 360
  @dark_text "#1e293b"
  @light_text "#ffffff"

  @doc """
  Returns a random pastel hex color.

  ## Options

    * `:saturation` - HSV saturation (default `#{@default_saturation}`)
    * `:value` - HSV value/brightness (default `#{@default_value}`)

  ## Examples

      iex> HashColorAvatar.random_color(saturation: 70, value: 100) |> String.match?(~r/^#[0-9A-F]{6}$/)
      true

  """
  def random_color(options \\ []) do
    <<n::unsigned-big-16>> = :crypto.strong_rand_bytes(2)
    seed = rem(n, @max_hue - 1) + 1
    saturation = Keyword.get(options, :saturation, @default_saturation)
    value = Keyword.get(options, :value, @default_value)
    hsv_to_rgb(%{hue: seed, saturation: saturation, value: value}) |> rgb_to_hex()
  end

  @doc """
  Converts a hue value to a hex color.

  ## Examples

      iex> HashColorAvatar.set_color(12)
      "#E58972"

      iex> HashColorAvatar.set_color(12, saturation: 70, value: 80)
      "#CC593D"

  """
  def set_color(hue_value, options \\ []) do
    saturation = Keyword.get(options, :saturation, @default_saturation)
    value = Keyword.get(options, :value, @default_value)

    %{hue: normalize_hue(hue_value), saturation: saturation, value: value}
    |> hsv_to_rgb()
    |> rgb_to_hex()
  end

  @doc """
  Converts an HSV map to an RGB map.

  ## Examples

      iex> HashColorAvatar.hsv_to_rgb(%{hue: 17, saturation: 50, value: 90})
      %{blue: 114, green: 147, red: 229}

  """
  def hsv_to_rgb(%{hue: hue, saturation: saturation, value: value}) do
    hue = normalize_hue(hue)
    saturation = clamp_float(saturation, 0, 100)
    value = clamp_float(value, 0, 100)

    h = hue / 60
    i = trunc(Float.floor(h))
    f = h - i
    sat_dec = saturation / 100

    p = value * (1 - sat_dec)
    q = value * (1 - sat_dec * f)
    t = value * (1 - sat_dec * (1 - f))

    p_rgb = rgb_channel(p)
    v_rgb = rgb_channel(value)
    t_rgb = rgb_channel(t)
    q_rgb = rgb_channel(q)

    case i do
      0 -> %{red: v_rgb, green: t_rgb, blue: p_rgb}
      1 -> %{red: q_rgb, green: v_rgb, blue: p_rgb}
      2 -> %{red: p_rgb, green: v_rgb, blue: t_rgb}
      3 -> %{red: p_rgb, green: q_rgb, blue: v_rgb}
      4 -> %{red: t_rgb, green: p_rgb, blue: v_rgb}
      _ -> %{red: v_rgb, green: p_rgb, blue: q_rgb}
    end
  end

  @doc """
  Converts an RGB map to a hex color string.

  ## Examples

      iex> HashColorAvatar.rgb_to_hex(%{red: 12, green: 23, blue: 43})
      "#0C172B"

      iex> HashColorAvatar.rgb_to_hex(%{red: 121, green: 13, blue: 203})
      "#790DCB"

  """
  def rgb_to_hex(%{red: red, green: green, blue: blue}) do
    r = clamp_int(red, 0, 255)
    g = clamp_int(green, 0, 255)
    b = clamp_int(blue, 0, 255)
    "#" <> Base.encode16(<<r, g, b>>, case: :upper)
  end

  @doc """
  Generates an SVG avatar for the given text.

  The background color is derived from a hash of the text unless `:color` is set.
  Initials are optically centered with size tuned for one or two characters.

  ## Options

    * `:color` - `nil` (hash), `"grey"`, `"black"`, `"random"`, or any CSS/hex color
    * `:style` - `:modern` (default) or `:minimal`
    * `:shape` - `:circle` (default) or `:rect`
    * `:size` - positive integer pixel size (default `100`)
    * `:text_color` - initials color; auto-selected for contrast when omitted
    * `:font_family` - font stack for initials

  ## Examples

      iex> HashColorAvatar.gen_avatar("", style: :modern) |> String.contains?("<linearGradient")
      true

      iex> HashColorAvatar.gen_avatar("Samantha Johnson Abigail", color: "tomato", shape: :rect, size: 200) |> String.contains?("<rect")
      true

  """
  def gen_avatar(rawtext, options \\ []) do
    text = normalize_text(rawtext)
    initial = get_initial(text)

    color_opt = Keyword.get(options, :color)
    shape = normalize_shape(Keyword.get(options, :shape, @default_shape))
    size = validate_size!(Keyword.get(options, :size, @default_size))
    style = normalize_style(Keyword.get(options, :style, @default_style))
    font_family = Keyword.get(options, :font_family, @font_family) |> to_string()

    half = size / 2
    border_radius = max(ceil(size * 0.2), 8)
    id_suffix = Integer.to_string(:erlang.phash2({text, color_opt, shape, size, style}), 16)

    {defs, layers, sample_rgb} =
      build_layers(text, color_opt, shape, size, half, border_radius, style, id_suffix)

    text_color =
      case Keyword.get(options, :text_color) do
        nil -> readable_text_color(sample_rgb)
        custom -> to_string(custom)
      end

    {font_size, letter_spacing} = text_metrics(initial, size)

    text_svg =
      ~s(<text x="#{half}" y="#{half}" text-anchor="middle" dominant-baseline="central" fill="#{text_color}" style="font-weight:600;font-size:#{font_size}px;font-family:#{font_family};letter-spacing:#{letter_spacing};user-select:none">#{initial}</text>)

    ~s(<svg width="#{size}" height="#{size}" viewBox="0 0 #{size} #{size}" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="#{initial} avatar">#{defs}#{layers}#{text_svg}</svg>)
  end

  @doc """
  Extracts up to two initials from a name (first and last word).

  ## Examples

      iex> HashColorAvatar.get_initial("sujiwo tedjo")
      "ST"

      iex> HashColorAvatar.get_initial("guruh soekarno putra")
      "GP"

  """
  def get_initial(name) do
    parts =
      name
      |> then(&Regex.replace(~r/[\p{P}\p{S}\p{C}\p{N}]+/u, &1, " "))
      |> String.split(~r/\s+/, trim: true)

    case parts do
      [] ->
        @initial_fallback

      [word] ->
        word |> String.first() |> String.upcase()

      parts ->
        (String.first(hd(parts)) <> String.first(List.last(parts))) |> String.upcase()
    end
  end

  defp build_layers(text, color_opt, shape, size, half, border_radius, style, id_suffix) do
    case style do
      :modern -> build_modern_layers(text, color_opt, shape, size, half, border_radius, id_suffix)
      :minimal -> build_minimal_layers(text, color_opt, shape, size, half, border_radius)
    end
  end

  defp build_modern_layers(text, color_opt, shape, size, half, border_radius, id_suffix) do
    filter =
      ~s(<filter id="shadow-#{id_suffix}" x="-20%" y="-20%" width="140%" height="140%"><feDropShadow dx="0" dy="#{size * 0.03}" stdDeviation="#{size * 0.04}" flood-color="#000" flood-opacity="0.2"/></filter>)

    {gradient_or_fill, sample_rgb} =
      case resolve_color(color_opt, text) do
        {:hash, primary, secondary} ->
          c1 = palette_to_hex(primary)
          c2 = palette_to_hex(secondary)

          gradient =
            ~s(<linearGradient id="grad-#{id_suffix}" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#{c1}"/><stop offset="100%" stop-color="#{c2}"/></linearGradient>)

          sample = average_rgb(hsv_to_rgb(primary), hsv_to_rgb(secondary))
          {gradient, {:gradient, "url(#grad-#{id_suffix})", sample}}

        {:solid, hex, rgb} ->
          {nil, {:solid, hex, rgb}}
      end

    defs =
      case gradient_or_fill do
        nil -> ~s(<defs>#{filter}</defs>)
        gradient -> ~s(<defs>#{gradient}#{filter}</defs>)
      end

    {fill, sample} =
      case sample_rgb do
        {:gradient, fill, rgb} -> {fill, rgb}
        {:solid, fill, rgb} -> {fill, rgb}
      end

    fill_attr = "fill=\"#{fill}\" filter=\"url(#shadow-#{id_suffix})\""
    bg = shape_element(shape, size, half, border_radius, fill_attr)

    overlay_fill =
      shape_element(shape, size, half, border_radius, ~s(fill="#{@light_text}" opacity="0.08"))

    ring = ring_element(shape, size, half, border_radius)

    {defs, bg <> overlay_fill <> ring, sample}
  end

  defp build_minimal_layers(text, color_opt, shape, size, half, border_radius) do
    {_kind, hex, rgb} =
      case resolve_color(color_opt, text) do
        {:hash, primary, _secondary} -> {:solid, palette_to_hex(primary), hsv_to_rgb(primary)}
        {:solid, hex, rgb} -> {:solid, hex, rgb}
      end

    bg = shape_element(shape, size, half, border_radius, ~s(fill="#{hex}"))
    {"", bg, rgb}
  end

  defp resolve_color(nil, text) do
    primary = hash_palette(text)
    offset = 20 + rem(:erlang.phash2(text, @max_hue), 32)

    secondary_value =
      max(primary.value - 6 - rem(div(:erlang.phash2(text <> ":v", 64), 1), 8), 76)

    secondary = %{primary | hue: rem(primary.hue + offset, @max_hue), value: secondary_value}
    {:hash, primary, secondary}
  end

  defp resolve_color("grey", _text), do: {:solid, "#c3c3c3", %{red: 195, green: 195, blue: 195}}
  defp resolve_color("black", _text), do: {:solid, "#000000", %{red: 0, green: 0, blue: 0}}
  defp resolve_color("random", _text), do: random_color() |> hex_to_rgb_tuple()

  defp resolve_color(color, _text) when is_binary(color),
    do: {:solid, color, hex_or_named_to_rgb(color)}

  defp resolve_color(color, _text), do: resolve_color(to_string(color), nil)

  defp shape_element("rect", size, _half, border_radius, attrs) do
    ~s(<rect x="0" y="0" width="#{size}" height="#{size}" rx="#{border_radius}" ry="#{border_radius}" #{attrs}/>)
  end

  defp shape_element(_circle, _size, half, _border_radius, attrs) do
    ~s(<circle cx="#{half}" cy="#{half}" r="#{half}" #{attrs}/>)
  end

  defp ring_element("rect", size, _half, border_radius) do
    inset = max(size * 0.02, 1)
    inner_radius = max(border_radius - inset, 0)
    inner_size = max(size - inset * 2, 0)

    ~s(<rect x="#{inset}" y="#{inset}" width="#{inner_size}" height="#{inner_size}" rx="#{inner_radius}" ry="#{inner_radius}" fill="none" stroke="#{@light_text}" stroke-opacity="0.22" stroke-width="#{inset}"/>)
  end

  defp ring_element(_circle, _size, half, _border_radius) do
    inset = max(half * 0.04, 1)

    ~s(<circle cx="#{half}" cy="#{half}" r="#{max(half - inset, 0)}" fill="none" stroke="#{@light_text}" stroke-opacity="0.22" stroke-width="#{inset}"/>)
  end

  defp text_metrics(initial, size) do
    case String.length(initial) do
      1 -> {Float.round(size * 0.44, 2), "0"}
      _ -> {Float.round(size * 0.36, 2), "#{Float.round(size * 0.02, 2)}px"}
    end
  end

  defp hash_palette(text) do
    seed = :erlang.phash2(text, 1_000_000_000)
    hue = rem(seed, @max_hue)
    saturation = @default_saturation + rem(div(seed, @max_hue), 10)
    value = @default_value - rem(div(seed, @max_hue * 10), 7)
    %{hue: hue, saturation: saturation, value: value}
  end

  defp palette_to_hex(palette), do: palette |> hsv_to_rgb() |> rgb_to_hex()

  defp readable_text_color(rgb) do
    luminance = 0.2126 * rgb.red + 0.7152 * rgb.green + 0.0722 * rgb.blue

    if luminance > 150, do: @dark_text, else: @light_text
  end

  defp average_rgb(a, b) do
    %{red: div(a.red + b.red, 2), green: div(a.green + b.green, 2), blue: div(a.blue + b.blue, 2)}
  end

  defp hex_to_rgb_tuple("#" <> hex) when byte_size(hex) == 6 do
    <<r, g, b>> = Base.decode16!(hex, case: :mixed)
    {:solid, "#" <> String.upcase(hex), %{red: r, green: g, blue: b}}
  end

  defp hex_to_rgb_tuple(hex), do: {:solid, hex, %{red: 128, green: 128, blue: 128}}

  defp hex_or_named_to_rgb("#" <> hex) when byte_size(hex) == 6 do
    <<r, g, b>> = Base.decode16!(hex, case: :mixed)
    %{red: r, green: g, blue: b}
  end

  defp hex_or_named_to_rgb(_named), do: %{red: 128, green: 128, blue: 128}

  defp normalize_hue(hue) when is_integer(hue), do: rem(hue, @max_hue)
  defp normalize_hue(hue) when is_float(hue), do: hue |> trunc() |> normalize_hue()
  defp normalize_hue(hue), do: hue |> to_string() |> String.to_integer() |> normalize_hue()

  defp clamp_int(value, min, max) do
    value
    |> max(min)
    |> min(max)
  end

  defp clamp_float(value, min, max) do
    value = value * 1.0

    cond do
      value < min -> min
      value > max -> max
      true -> value
    end
  end

  defp normalize_text(nil), do: "V K"
  defp normalize_text(text) when is_binary(text), do: text
  defp normalize_text(other), do: to_string(other)

  defp normalize_shape("rect"), do: "rect"
  defp normalize_shape(:rect), do: "rect"
  defp normalize_shape(_), do: "circle"

  defp normalize_style(:modern), do: :modern
  defp normalize_style("modern"), do: :modern
  defp normalize_style(:minimal), do: :minimal
  defp normalize_style("minimal"), do: :minimal
  defp normalize_style(_), do: :modern

  defp validate_size!(size) when is_float(size), do: validate_size!(trunc(size))

  defp validate_size!(size) when is_integer(size) and size > 0, do: size

  defp validate_size!(size) do
    raise ArgumentError, "expected :size to be a positive integer, got: #{inspect(size)}"
  end

  defp rgb_channel(color), do: trunc(color * 255 / 100)
end
