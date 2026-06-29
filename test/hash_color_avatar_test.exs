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
    assert String.contains?(svg, "dominant-baseline=\"central\"")
    assert String.contains?(svg, "text-anchor=\"middle\"")
    assert String.contains?(svg, "<linearGradient")
    assert String.contains?(svg, "feDropShadow")
  end

  test "test create avatar minimal style" do
    svg = HashColorAvatar.gen_avatar("Marlyn Monroe", style: :minimal)

    refute String.contains?(svg, "<linearGradient")
    refute String.contains?(svg, "feDropShadow")
  end

  test "test create avatar 5 name option rectangle" do
    svg =
      HashColorAvatar.gen_avatar("Sagit Putri Lestari Harum Mewangi", shape: "rect")

    assert String.starts_with?(svg, "<svg")
    assert String.contains?(svg, "<rect")
    assert String.contains?(svg, "rx=")
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

    assert one =~ ~r/font-size:44(\.0)?px/
    assert two =~ ~r/font-size:36(\.0)?px/
  end
end
