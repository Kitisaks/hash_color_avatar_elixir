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

  test "test create avatar 2 name" do
    svg = HashColorAvatar.gen_avatar("Marlyn Monroe") |> to_string()

    assert String.starts_with?(svg, "<svg")
    assert String.contains?(svg, "<circle")
    assert String.contains?(svg, ">MM</text>")
    assert String.contains?(svg, "dominant-baseline=\"middle\"")
    refute String.contains?(svg, "<linearGradient")
    refute String.contains?(svg, "feDropShadow")
  end

  test "test create avatar 5 name option rectangle" do
    svg =
      HashColorAvatar.gen_avatar("Sagit Putri Lestari Harum Mewangi", shape: "rect")
      |> to_string()

    assert String.starts_with?(svg, "<svg")
    assert String.contains?(svg, "<rect")
    assert String.contains?(svg, "rx=")
    assert String.contains?(svg, ">SM</text>")
    refute String.contains?(svg, "<circle")
    refute String.contains?(svg, "<linearGradient")
    refute String.contains?(svg, "feDropShadow")
  end

  test "test create avatar modern style adds gradient+shadow" do
    svg =
      HashColorAvatar.gen_avatar("Marlyn Monroe", style: :modern) |> to_string()

    assert String.contains?(svg, "<linearGradient")
    assert String.contains?(svg, "feDropShadow")
  end
end
