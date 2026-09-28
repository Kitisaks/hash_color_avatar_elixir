defmodule HashColorAvatar do
  @moduledoc """
  Generate deterministic SVG initial avatars.

  Hash colors are a fixed cool-neutral palette. Every swatch keeps white initials
  at WCAG AA (4.5:1) and stays visible on Tatex light paper (`#f4f4f6`) and dark
  chrome (`#262830`). The same name always maps to the same swatch.

  `gen_avatar/2` returns an SVG binary. `:minimal` is a flat disc for lists and
  headers. `:modern` adds a hairline rim and still skips filters and gradients.
  """

  @default_shape :circle
  @default_size 100
  @default_style :modern
  @default_saturation 50
  @default_value 90
  @font_family "Inter, ui-sans-serif, system-ui, sans-serif"
  @initial_fallback "VK"
  @max_hue 360
  @dark_text "#16171d"
  @light_text "#ffffff"
  @noise_pattern ~r/[\p{P}\p{S}\p{C}\p{N}]+/u
  @split_pattern ~r/\s+/u

  # Luminance sits in a narrow band: white initials stay >= 4.5:1, and the disc
  # stays >= 3:1 against Tatex gray-800 (`#262830`) in dark mode.
  @palette {
    {"#AC5D5D", %{red: 172, green: 93, blue: 93}},
    {"#8E6D4D", %{red: 142, green: 109, blue: 77}},
    {"#767640", %{red: 118, green: 118, blue: 64}},
    {"#607C43", %{red: 96, green: 124, blue: 67}},
    {"#458045", %{red: 69, green: 128, blue: 69}},
    {"#447F62", %{red: 68, green: 127, blue: 98}},
    {"#437C7C", %{red: 67, green: 124, blue: 124}},
    {"#53769A", %{red: 83, green: 118, blue: 154}},
    {"#6969C3", %{red: 105, green: 105, blue: 195}},
    {"#8B61B4", %{red: 139, green: 97, blue: 180}},
    {"#A258A2", %{red: 162, green: 88, blue: 162}},
    {"#A85A81", %{red: 168, green: 90, blue: 129}}
  }
  @palette_size tuple_size(@palette)

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

  ## Options

    * `:saturation` - HSV saturation (default `#{@default_saturation}`)
    * `:value` - HSV value/brightness (default `#{@default_value}`)

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

  The background is chosen from the hash palette unless `:color` is set.
  Initials use Inter when the host page loads it, with the baseline set so
  uppercase caps sit on the optical center. Output is a flat SVG: no filters,
  no gradients.

  ## Options

    * `:color` - `nil` (hash palette), `"grey"`, `"black"`, `"random"`, or a hex/CSS color
    * `:style` - `:modern` (default, flat fill plus hairline rim) or `:minimal` (fill only)
    * `:shape` - `:circle` (default) or `:rect`
    * `:size` - positive integer pixel size (default `100`)
    * `:text_color` - initials color; auto-selected for contrast when omitted
    * `:font_family` - font stack for initials (default Inter, then system UI)

  ## Examples

      iex> HashColorAvatar.gen_avatar("", style: :modern) |> String.contains?(">VK</text>")
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

    {hex, sample_rgb} = resolve_fill(color_opt, text)

    text_color =
      case Keyword.get(options, :text_color) do
        nil -> readable_text_color(sample_rgb)
        custom -> to_string(custom)
      end

    {font_size, baseline, tracking} = text_layout(initial, size)
    radius = corner_radius(size)
    half = size / 2

    layers = [shape_element(shape, size, half, radius, xml_escape(hex))]

    layers =
      if style == :modern do
        [layers, rim_element(shape, size, half, radius)]
      else
        layers
      end

    svg = [
      ~s(<svg width="),
      Integer.to_string(size),
      ~s(" height="),
      Integer.to_string(size),
      ~s(" viewBox="0 0 ),
      Integer.to_string(size),
      " ",
      Integer.to_string(size),
      ~s(" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="),
      xml_escape(initial),
      ~s( avatar">),
      layers,
      text_element(initial, half, baseline, font_size, tracking, text_color, font_family),
      "</svg>"
    ]

    IO.iodata_to_binary(svg)
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
      |> then(&Regex.replace(@noise_pattern, &1, " "))
      |> String.split(@split_pattern, trim: true)

    case parts do
      [] ->
        @initial_fallback

      [word] ->
        word |> String.first() |> String.upcase()

      parts ->
        (String.first(hd(parts)) <> String.first(List.last(parts))) |> String.upcase()
    end
  end

  defp resolve_fill(nil, text), do: palette_color(text)
  defp resolve_fill("grey", _text), do: {"#C3C3C3", %{red: 195, green: 195, blue: 195}}
  defp resolve_fill("black", _text), do: {"#000000", %{red: 0, green: 0, blue: 0}}

  defp resolve_fill("random", _text) do
    hex = random_color()
    {_kind, hex, rgb} = hex_to_rgb_tuple(hex)
    {hex, rgb}
  end

  defp resolve_fill(color, _text) when is_binary(color) do
    {color, hex_or_named_to_rgb(color)}
  end

  defp resolve_fill(color, text), do: resolve_fill(to_string(color), text)

  defp palette_color(text) do
    elem(@palette, rem(:erlang.crc32(text), @palette_size))
  end

  defp shape_element("rect", size, _half, radius, fill) do
    radius = num(radius)

    ~s(<rect x="0" y="0" width="#{size}" height="#{size}" rx="#{radius}" ry="#{radius}" fill="#{fill}"/>)
  end

  defp shape_element(_circle, _size, half, _radius, fill) do
    half = num(half)
    ~s(<circle cx="#{half}" cy="#{half}" r="#{half}" fill="#{fill}"/>)
  end

  defp rim_element("rect", size, _half, radius) do
    inset = max(size * 0.035, 1)
    inner = num(max(size - inset * 2, 0))
    inner_radius = num(max(radius - inset, 0))
    inset = num(inset)

    ~s(<rect x="#{inset}" y="#{inset}" width="#{inner}" height="#{inner}" rx="#{inner_radius}" ry="#{inner_radius}" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="#{inset}"/>)
  end

  defp rim_element(_circle, _size, half, _radius) do
    inset = max(half * 0.06, 1)
    radius = num(max(half - inset / 2, 0))
    half = num(half)
    inset = num(inset)

    ~s(<circle cx="#{half}" cy="#{half}" r="#{radius}" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="#{inset}"/>)
  end

  defp text_element(initial, x, y, font_size, tracking, text_color, font_family) do
    [
      ~s(<text x="),
      num(x),
      ~s(" y="),
      num(y),
      ~s(" text-anchor="middle" fill="),
      xml_escape(text_color),
      ~s(" font-family="),
      xml_escape(font_family),
      ~s(" font-weight="600" font-size="),
      num(font_size),
      ~s(" letter-spacing="),
      tracking,
      ~s(">),
      xml_escape(initial),
      "</text>"
    ]
  end

  defp text_layout(initial, size) do
    single? = String.length(initial) == 1
    font_size = size * if(single?, do: 0.42, else: 0.34)
    font_size = Float.round(font_size, 2)
    # Inter cap-height is ~0.72em. Shift the baseline so the caps, not the em box, center.
    baseline = Float.round(size / 2 + font_size * 0.36, 2)
    tracking = if single?, do: "0", else: "-0.03em"
    {font_size, baseline, tracking}
  end

  defp corner_radius(size), do: max(size * 0.22, 4)

  defp readable_text_color(%{red: red, green: green, blue: blue}) do
    fill = {red, green, blue}
    light = contrast_ratio(fill, {255, 255, 255})
    dark = contrast_ratio(fill, {22, 23, 29})
    if light >= dark, do: @light_text, else: @dark_text
  end

  defp contrast_ratio(a, b) do
    hi = relative_luminance(a)
    lo = relative_luminance(b)
    {hi, lo} = if hi > lo, do: {hi, lo}, else: {lo, hi}
    (hi + 0.05) / (lo + 0.05)
  end

  defp relative_luminance({red, green, blue}) do
    0.2126 * channel_luminance(red) + 0.7152 * channel_luminance(green) +
      0.0722 * channel_luminance(blue)
  end

  defp channel_luminance(channel) do
    value = channel / 255

    if value <= 0.04045 do
      value / 12.92
    else
      :math.pow((value + 0.055) / 1.055, 2.4)
    end
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

  defp normalize_hue(hue) when is_integer(hue), do: Integer.mod(hue, @max_hue)
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

  defp xml_escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp num(value) when is_integer(value), do: Integer.to_string(value)

  defp num(value) when is_float(value) do
    rounded = Float.round(value, 2)

    if rounded == trunc(rounded) do
      Integer.to_string(trunc(rounded))
    else
      :erlang.float_to_binary(rounded, [:compact, decimals: 2])
    end
  end
end
