defmodule ReqFuse do
  @external_resource "README.md"
  @moduledoc @external_resource
             |> File.read!()
             |> String.split("<!-- MDOC -->")
             |> Enum.fetch!(1)

  alias ReqFuse.Steps.Fuse

  defdelegate attach(req, opts), to: Fuse
end
