defmodule ReqFuse.MixProject do
  use Mix.Project

  @name "ReqFuse"
  @source_url "https://github.com/carsdotcom/req_fuse"
  @version "0.1.0"
  
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
      package: package(),
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false, optional: true, app: false},
      {:fuse, ">= 2.4.0"},
      {:req, ">= 0.3.0"}
    ]
  end

  defp description do
     "ReqFuse is a Req plugin for the fuse circuit-breaker library."
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
        #"CHANGELOG.md"
      ]
    ]
  end

end
