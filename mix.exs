defmodule HashColorAvatar.MixProject do
  use Mix.Project

  def project do
    [
      app: :hash_color_avatar,
      version: "0.1.0",
      elixir: "~> 1.14",
      description:
        "A simple SVG initial avatar generator with pastel color generated from string hash.",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps()
    ]
  end

  def package do
    [
      name: :hash_color_avatar,
      files: ["lib", "mix.exs"],
      maintainers: ["virkillz"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/virkillz/hash_color_avatar_elixir"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [{:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true}]
  end
end
