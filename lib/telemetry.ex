defmodule ReqFuse.Telemetry do
  @moduledoc """
  Telemetry integration for fuse events.

  ### Runtime Events

  * `[:req_fuse, :blown]` - This event will fire whenever a fuse is checked and is in a blown state.

  ### Metadata

  * `:fuse_name` - the name of the fuse

  """

  @spec blown_fuse(:atom) :: :ok
  def blown_fuse(fuse_name) do
    :telemetry.execute([:req_fuse, :blown], %{}, %{fuse_name: fuse_name})
  end
end
