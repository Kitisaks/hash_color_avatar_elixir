defmodule HashColorAvatar do
  @default_color :pastel
  @default_shape :circle
  @default_size 100
  @default_saturation 50
  @default_value 90

  import Bitwise

  @moduledoc """
  This is a small library to generate SVG initial avatar with unique-ish color based on string hash.

  The primary feature is to generate on the fly SVG for default avatar. The user can get unique avatar (to certain degree) based on his name innitial and the unique color generated by hashing its name. Please be noted that of couse same name will resulting to the same image. And eventhough there are thousands of color exist, we choose to make the saturation fix so there can only be 359 possible color.

  Another function will be quite useful as well such as random_color/1, will give you nice pastel random color which you can use as background or anything.

  set_color/2 can be used to make color by specifying the hue value.

  Function to Generate Initial from name, gen_initial/1 can also be used independently.

  """

  @doc """
  Will generate random color in hex.

  ## Options
  This color is generated by randomizing HSV (Hue Saturation Value) with default Saturation is set to 50 and Value set to 90.
  ``` iex> HashColorAvatar.random_color([saturation: 70, value: 100])

  """

  def random_color(options \\ []) do
    seed = :rand.uniform(359)
    saturation = Keyword.get(options, :saturation, @default_saturation)
    value = Keyword.get(options, :value, @default_value)
    hsv_to_rgb(%{hue: seed, saturation: saturation, value: value}) |> rgb_to_hex
  end

  @doc """
  This function will convert RGB to hex.

  ## Examples

      iex> HashColorAvatar.set_color(12)
      "#E58972"

  Option also applied

      iex> HashColorAvatar.set_color(12, [saturation: 70, value: 80])
      "#CC593D"

  """
  def set_color(hue_value, options \\ []) do
    saturation = Keyword.get(options, :saturation, @default_saturation)
    value = Keyword.get(options, :value, @default_value)
    hsv_to_rgb(%{hue: hue_value, saturation: saturation, value: value}) |> rgb_to_hex
  end

  @doc """
  This function will convert HSV map to RGB map.

  ## Examples

      iex> HashColorAvatar.hsv_to_rgb(%{hue: 17, saturation: 50, value: 90})
      %{blue: 114, green: 147, red: 229}

  """
  def hsv_to_rgb(%{hue: hue, saturation: saturation, value: value} = _hsv) do
    h = hue / 60
    i = Float.floor(h) |> trunc()
    f = h - i

    sat_dec = saturation / 100

    p = value * (1 - sat_dec)
    q = value * (1 - sat_dec * f)
    t = value * (1 - sat_dec * (1 - f))

    p_rgb = get_rgb_color(p)
    v_rgb = get_rgb_color(value)
    t_rgb = get_rgb_color(t)
    q_rgb = get_rgb_color(q)

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
  This function will convert RGB to hex.

  ## Examples

      iex> HashColorAvatar.rgb_to_hex(%{red: 12, green: 23, blue: 43})
      "#0C172B"

      iex> HashColorAvatar.rgb_to_hex(%{red: 121, green: 13, blue: 203})
      "#790DCB"

  """
  def rgb_to_hex(%{red: red, green: green, blue: blue} = _rgb) do
    hex =
      ((1 <<< 24) + (red <<< 16) + (green <<< 8) + blue)
      |> Integer.to_string(16)
      |> String.slice(1..1500)

    "#" <> hex
  end

  @doc """
  Given some string, this function will generate SVG avatar. The main feature is the micro hasing function. Which means th ecolor given for "Frank Abraham" will be different for "Foreman Abdul" even though they both have same initials.

  ## Examples

      iex> HashColorAvatar.gen_avatar("")
      ~c{<svg width="100" height="100"><circle cx="50.0" cy="50.0" r="50.0" stroke="white" stroke-width="4" fill="pastel" /><text fill="white" x="50%" y="67%" text-anchor="middle" style="font: bold 41.66666666666667px sans-serif;" >VK</text></circle></svg>}

  ## Option
  **:color** can be used to specify background color. By default it will generate hash based on the text given. It will be unique-ish since there are only 359 possible color and there's a chance it looks similar one amongst the other. For the value you can choose "random", any color code recognized by CSS such as "teal", "tomato", also it accept hex code.

  **:shape** by default is circle. You can also choose "rect" for rectangle avatar.

  **:size** You can define how many pixel height and width. Default is 100

  ## Examples

      iex> HashColorAvatar.gen_avatar("Samantha Johnson Abigail", [color: "tomato", shape: "rect", size: 200])
      ~c{<svg width="200" height="200"><rect width="200" height="200" fill="tomato" /><text fill="white" x="50%" y="65%" text-anchor="middle" style="font: bold 83.33333333333334px sans-serif;" >SA</text></circle></svg>}


  """
  def gen_avatar(rawtext, options \\ []) do
    text = if rawtext == nil, do: "V K", else: rawtext

    color = Keyword.get(options, :color, @default_color)
    shape = Keyword.get(options, :shape, @default_shape)
    size = Keyword.get(options, :size, @default_size)

    fontsize = size / 2.4

    diameter = size / 2

    background_color =
      case color do
        "grey" -> "#c3c3c3"
        "black" -> "black"
        "random" -> random_color()
        nil -> text |> minihash |> set_color
        custom -> custom
      end

    case shape do
      "rect" ->
        ~c{<svg width="#{size}" height="#{size}"><rect width="#{size}" height="#{size}" fill="#{background_color}" /><text fill="white" x="50%" y="65%" text-anchor="middle" style="font: bold #{fontsize}px sans-serif;" >#{get_initial(text)}</text></circle></svg>}

      _other ->
        ~c{<svg width="#{size}" height="#{size}"><circle cx="#{diameter}" cy="#{diameter}" r="#{diameter}" stroke="white" stroke-width="4" fill="#{background_color}" /><text fill="white" x="50%" y="67%" text-anchor="middle" style="font: bold #{fontsize}px sans-serif;" >#{get_initial(text)}</text></circle></svg>}
    end
  end

  @doc """
  This function generate initial from any given name. If more than 2 word given it will take initial first and last word. It will try to ignore other character.

  ## Examples

      iex> HashColorAvatar.get_initial("sujiwo tedjo")
      "ST"

      iex> HashColorAvatar.get_initial("guruh soekarno putra")
      "GP"

  """
  def get_initial(name) do
    clean_character =
      Regex.replace(~r/[\p{P}\p{S}\p{C}\p{N}]+/, name, "") |> String.trim() |> String.split()

    case Enum.count(clean_character) do
      0 ->
        "VK"

      1 ->
        clean_character |> List.first() |> String.at(0) |> String.upcase()

      _other ->
        first = clean_character |> List.first() |> String.at(0) |> String.upcase()
        second = clean_character |> List.last() |> String.at(0) |> String.upcase()
        first <> second
    end
  end

  @doc false
  # This function will generate "hash" for any kind of string and spitting integer
  # between 1 to 359. This the possible Hue range in color
  defp minihash(string) do
    :crypto.hash(:md5, string)
    |> Base.encode16()
    |> String.slice(0..3)
    |> String.graphemes()
    |> string_to_int
    |> rem(360)
  end

  @doc false
  # This function is private function to convert part of hashed string into interger.
  defp string_to_int(list) do
    Enum.reduce(list, 1, fn x, acc ->
      case Integer.parse(x) do
        {0, _} -> 1 * acc
        {number, _} -> number * acc
        :error -> letter_to_integer(x) * acc
      end
    end)
  end

  @doc false
  defp get_rgb_color(color) do
    (color * 255 / 100) |> trunc()
  end

  @doc false
  defp letter_to_integer(letter) do
    case letter do
      "A" -> 1
      "B" -> 2
      "C" -> 3
      "D" -> 4
      "E" -> 5
      "F" -> 6
      _other -> 1
    end
  end
end
