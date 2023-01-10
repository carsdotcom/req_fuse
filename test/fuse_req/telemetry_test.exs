defmodule ReqFuse.TelemetryTest do
  use ExUnit.Case

  alias ReqFuse.Telemetry

  describe "blown_fuse/1" do
    test "emits a telemetry event with the given name" do
      ref = :telemetry_test.attach_event_handlers(self(), [[:req_fuse, :blown]])
      Telemetry.blown_fuse(:test_blown_fuse)
      assert_received {[:req_fuse, :blown], ^ref, _, %{fuse_name: :test_blown_fuse}}
    end
  end
end
