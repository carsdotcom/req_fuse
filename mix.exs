defmodule ReqFuse.MixProject do
  use Mix.Project

  @name "ReqFuse"
  @source_url "https://github.com/carsdotcom/req_fuse"
  @version "0.2.4"

  def project do
    [
      app: :req_fuse,
      name: @name,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: description(),
      contributors: contributors(),
      package: package(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def contributors() do
    [
      {"Christian Koch", "@ckochx"}
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false, optional: true, app: false},
      # based on the changelog and commits, anything prior to 2.4.0 is more than 5 years old, and
      # I suspect, has some differrence in the API. However if there's a use case for earlier fuse
      # versions, I'm happy to consider a PR.
      {:fuse, ">= 2.4.0"},
      {:req, ">= 0.3.0"},
      {:telemetry, "~> 1.0 or ~> 0.4"}
    ]
  end

  defp description do
    """
    ReqFuse provides circuit-breaking functionality, using fuse, for HTTP requests that use Req.
    Req: https://github.com/wojtekmach/req
    Fuse: ttps://github.com/jlouis/fuse
    """
  end

  defp package() do
    [
      description: description(),
      licenses: ["CC-BY-NC-ND-4.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      logo: "assets/fuse.png",
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end
