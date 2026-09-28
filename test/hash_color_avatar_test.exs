defmodule HashColorAvatarTest do
  use ExUnit.Case
  doctest HashColorAvatar

  test "generate initial empty" do
    assert HashColorAvatar.get_initial("") == "VK"
  end

  test "generate initial one name" do
    assert HashColorAvatar.get_initial("sandra") == "S"
  end

  test "generate initial two name" do
    assert HashColorAvatar.get_initial("guruh soekarno") == "GS"
  end

  test "generate initial from unicode names" do
    assert HashColorAvatar.get_initial("Дмитрий") == "Д"
    assert HashColorAvatar.get_initial("Иван Петров") == "ИП"
    assert HashColorAvatar.get_initial("José García") == "JG"
  end

  test "gen_avatar with unicode names produces valid utf-8" do
    svg = HashColorAvatar.gen_avatar("Иван Петров", style: :minimal)

    assert String.valid?(svg)
    assert String.contains?(svg, ">ИП</text>")
  end

  test "generate initial three name" do
    assert HashColorAvatar.get_initial("guruh soekarno putra") == "GP"
  end

  test "test convert HSV to RGB" do
    assert HashColorAvatar.hsv_to_rgb(%{hue: 18, saturation: 50, value: 90}) == %{
             blue: 114,
             green: 149,
             red: 229
           }
  end

  test "test convert RGB to HEX" do
    assert HashColorAvatar.rgb_to_hex(%{red: 14, green: 13, blue: 12}) == "#0E0D0C"
  end

  test "test create avatar 2 name modern by default" do
    svg = HashColorAvatar.gen_avatar("Marlyn Monroe")

    assert String.starts_with?(svg, "<svg")
    assert String.contains?(svg, "<circle")
    assert String.contains?(svg, ">MM</text>")
    assert String.contains?(svg, "text-anchor=\"middle\"")
    assert String.contains?(svg, "stroke-opacity=\"0.35\"")
    assert svg =~ ~r/<circle cx="50" cy="50" r="50" fill="#[0-9A-F]{6}"\/>/
    assert String.contains?(svg, "Inter, ui-sans-serif")
    refute String.contains?(svg, "<linearGradient")
    refute String.contains?(svg, "feDropShadow")
    refute String.contains?(svg, "<filter")
  end

  test "test create avatar minimal style" do
    svg = HashColorAvatar.gen_avatar("Marlyn Monroe", style: :minimal)

    refute String.contains?(svg, "<linearGradient")
    refute String.contains?(svg, "feDropShadow")
    refute String.contains?(svg, "stroke-opacity")
    refute String.contains?(svg, "<filter")
    assert svg =~ ~r/<circle cx="50" cy="50" r="50" fill="#[0-9A-F]{6}"\/>/
  end

  test "test create avatar 5 name option rectangle" do
    svg =
      HashColorAvatar.gen_avatar("Sagit Putri Lestari Harum Mewangi", shape: "rect")

    assert String.starts_with?(svg, "<svg")

    assert svg =~
             ~r/<rect x="0" y="0" width="100" height="100" rx="22" ry="22" fill="#[0-9A-F]{6}"\/>/

    assert String.contains?(svg, ">SM</text>")
    refute String.contains?(svg, "<circle")
  end

  test "hash palette is deterministic" do
    svg_a = HashColorAvatar.gen_avatar("Ada Lovelace", style: :minimal)
    svg_b = HashColorAvatar.gen_avatar("Ada Lovelace", style: :minimal)
    assert svg_a == svg_b
  end

  test "single initial uses larger font than two initials" do
    one = HashColorAvatar.gen_avatar("sandra", style: :minimal)
    two = HashColorAvatar.gen_avatar("sandra lee", style: :minimal)

    assert one =~ ~r/font-size="42"/
    assert two =~ ~r/font-size="34"/
  end

  test "hash fills stay readable on white text and tatex dark chrome" do
    fills =
      for i <- 0..240, into: MapSet.new() do
        svg =
          HashColorAvatar.gen_avatar("traveler #{i}",
            style: :minimal,
            text_color: "#ffffff",
            size: 40
          )

        [hex] = Regex.run(~r/fill="(#[0-9A-F]{6})"/, svg, capture: :all_but_first)
        assert contrast(hex, "#FFFFFF") >= 4.5
        assert contrast(hex, "#262830") >= 3.0
        assert contrast(hex, "#F4F4F6") >= 3.0
        hex
      end

    assert MapSet.size(fills) == 12
  end

  test "tatex embed sizes stay flat and use inter" do
    for size <- [32, 40, 48, 120, 160] do
      svg =
        HashColorAvatar.gen_avatar("Marlyn Monroe",
          style: :minimal,
          text_color: "#ffffff",
          size: size
        )

      assert String.starts_with?(svg, ~s(<svg width="#{size}"))
      assert svg =~ ">MM</text>"
      assert svg =~ "font-family=\"Inter, ui-sans-serif, system-ui, sans-serif\""
      refute svg =~ "<filter"
      refute svg =~ "letter-spacing=\"0."
    end
  end

  test "escapes quotes in caller-supplied text color" do
    svg = HashColorAvatar.gen_avatar("Ada Lovelace", text_color: ~s(#fff"><script))

    refute svg =~ "<script"
    assert svg =~ "fill=\"#fff&quot;&gt;&lt;script\""
  end

  defp contrast(hex_a, hex_b) do
    hi = luminance(hex_a)
    lo = luminance(hex_b)
    {hi, lo} = if hi > lo, do: {hi, lo}, else: {lo, hi}
    (hi + 0.05) / (lo + 0.05)
  end

  defp luminance("#" <> hex) do
    <<r, g, b>> = Base.decode16!(hex, case: :mixed)

    0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
  end

  defp channel(value) do
    value = value / 255

    if value <= 0.04045 do
      value / 12.92
    else
      :math.pow((value + 0.055) / 1.055, 2.4)
    end
  end
end
