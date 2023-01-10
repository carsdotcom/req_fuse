defmodule ReqFuseTest do
  use ExUnit.Case

  doctest ReqFuse

  describe "attach/2" do
    test "key :fuse_name is required" do
      options = [fuse_opts: {}]

      assert_raise KeyError,
                   "key :fuse_name not found in: [fuse_opts: {}]",
                   fn ->
                     Req.new()
                     |> ReqFuse.attach(options)
                   end
    end

    test "configure fuse in the request and response step" do
      options = [fuse_name: "some-test-fuse-name"]

      req =
        [adapter: &FuseReq.Steps.FuseTest.TestAdapter.success/1]
        |> Req.new()
        |> ReqFuse.attach(options)

      Req.request!(req)

      assert Enum.member?(Keyword.keys(req.request_steps), :fuse)
      assert Enum.member?(Keyword.keys(req.response_steps), :fuse)

      request_func = Keyword.get(req.request_steps, :fuse)
      assert %Req.Request{} = request_func.(req)
    end
  end
end
