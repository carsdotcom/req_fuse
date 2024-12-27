defmodule FuseReq.Steps.FuseTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  alias FuseReq.Steps.FuseTest.TestAdapter
  alias ReqFuse.Steps.Fuse

  doctest ReqFuse.Steps.Fuse

  setup context do
    name = context.test

    on_exit(fn ->
      :fuse.remove(name)
    end)

    {:ok, name: name}
  end

  describe "defaults/0" do
    test "value" do
      assert Fuse.defaults() == {{:standard, 10, 10_000}, {:reset, 30_000}}
    end
  end

  describe "attach/2" do
    test "key :fuse_name is required" do
      options = [fuse_opts: {}]

      assert_raise KeyError,
                   "key :fuse_name not found in: [fuse_opts: {}]",
                   fn ->
                     Req.new()
                     |> Fuse.attach(options)
                   end
    end

    test "configure fuse in the request and response step", %{name: name} do
      options = [fuse_name: name]

      req =
        [adapter: &TestAdapter.success/1]
        |> Req.new()
        |> Fuse.attach(options)

      Req.request!(req)

      assert Enum.member?(Keyword.keys(req.request_steps), :fuse)
      assert Enum.member?(Keyword.keys(req.response_steps), :fuse)

      request_func = Keyword.get(req.request_steps, :fuse)
      assert %Req.Request{} = request_func.(req)
    end

    test "ignore non-fuse keys", %{name: name} do
      options = [
        fuse_name: name,
        fuse_opts: {{:standard, 1, 3000}, {:reset, 1000}},
        ignored_key: :ignored_value
      ]

      req =
        [adapter: &TestAdapter.not_found/1]
        |> Req.new()
        |> Fuse.attach(options)

      assert Map.has_key?(req.options, :fuse_name)
      assert Map.has_key?(req.options, :fuse_opts)
      refute Map.has_key?(req.options, :ignored_key)
    end

    test "override the melt function", %{name: name} do
      options = [
        fuse_name: name,
        fuse_opts: {{:standard, 1, 3000}, {:reset, 1000}},
        fuse_melt_func: fn
          %{status: status} -> status >= 404
          _ -> false
        end
      ]

      req =
        [adapter: &TestAdapter.not_found/1]
        |> Req.new()
        |> Fuse.attach(options)

      Req.request!(req)
      assert :ok = :fuse.ask(name, :sync)
      Req.request!(req)
      assert :blown = :fuse.ask(name, :sync)
    end

    test "500 status retries will trigger melt and blown fuse", %{name: name} do
      options = [
        fuse_name: name,
        fuse_opts: {{:standard, 2, 3000}, {:reset, 1000}}
      ]

      req =
        [adapter: &TestAdapter.failed/1, retry: :safe_transient, max_retries: 2, retry_delay: 50]
        |> Req.new()
        |> Fuse.attach(options)

      _log =
        capture_log(fn ->
          Req.request!(req)
        end)

      assert :blown = :fuse.ask(name, :sync)
    end

    test "exceptions without a :reason will not retry, but fuse will still blow", %{name: name} do
      options = [
        fuse_name: name,
        fuse_opts: {{:standard, 1, 3000}, {:reset, 1000}}
      ]

      # If all the requests are exceptions, the fuse will never get installed.
      # install it 'manually'
      :fuse.install(name, {{:standard, 1, 3000}, {:reset, 1000}})

      req =
        [
          adapter: &TestAdapter.exception/1,
          max_retries: 1
        ]
        |> Req.new()
        |> Fuse.attach(options)

      try do
        Req.request!(req)
      rescue
        e -> e
      end

      try do
        log =
          capture_log(fn ->
            Req.request!(req)
          end)

        assert log =~ "[warning] :fuse circuit breaker is open; fuse = #{name}"
      rescue
        e -> e
      end

      assert :blown = :fuse.ask(name, :sync)
    end

    test "exceptions with a :reason will retry and will trigger melt and blown fuse", %{
      name: name
    } do
      options = [
        fuse_name: name,
        fuse_opts: {{:standard, 1, 3000}, {:reset, 1000}}
      ]

      req =
        [
          adapter: &TestAdapter.closed/1,
          # retry: :safe_transient,
          max_retries: 1,
          retry_delay: 50
        ]
        |> Req.new()
        |> Fuse.attach(options)

      try do
        log =
          capture_log(fn ->
            Req.request!(req)
          end)

        assert log =~ "[warning] :fuse circuit breaker is open; fuse = #{name}"
      rescue
        e -> e
      end

      assert :blown = :fuse.ask(name, :sync)
    end

    test "setting :keep_original_error key gets dropped", %{name: name} do
      options = [
        fuse_name: name,
        fuse_keep_original_error: false
      ]

      req = Fuse.attach(Req.new(), options)
      refute Map.has_key?(req.options, :fuse_keep_original_error)
    end

    test "response when fuse is melted a request and response step", %{name: name} do
      options = [fuse_name: name]

      req =
        [adapter: &TestAdapter.failed/1, retry: false]
        |> Req.new()
        |> Fuse.attach(options)

      :fuse.install(name, {{:standard, 1, 3000}, {:reset, 1000}})
      :fuse.melt(name)
      :fuse.melt(name)

      _log =
        capture_log(fn ->
          {:error, exception} = Req.request(req)
          assert exception == %RuntimeError{message: "circuit breaker is open"}
        end)
    end

    test "eval 5XX response, melt, and trigger blown fuse", %{name: name} do
      options = [
        fuse_opts: {{:standard, 1, 3000}, {:reset, 1000}},
        fuse_name: name
      ]

      req =
        [adapter: &TestAdapter.failed/1, retry: false]
        |> Req.new()
        |> Fuse.attach(options)

      Req.request!(req)

      assert :ok = :fuse.ask(name, :sync)

      Req.request!(req)

      assert :blown = :fuse.ask(name, :sync)
    end

    test "logs a warning when the fuse is melted", %{name: name} do
      options = [fuse_name: name]

      req =
        [adapter: &TestAdapter.failed/1, retry: false]
        |> Req.new()
        |> Fuse.attach(options)

      :fuse.install(name, {{:standard, 1, 3000}, {:reset, 1000}})
      :fuse.melt(name)
      :fuse.melt(name)

      logs =
        capture_log([level: :warning], fn ->
          Req.request(req)
        end)

      assert logs =~ "[warning] :fuse circuit breaker is open"
      assert logs =~ "fuse = #{name}"
    end

    test "swallow log when verbose = false", %{name: name} do
      options = [fuse_name: name, fuse_verbose: false]

      req =
        [adapter: &TestAdapter.failed/1, retry: false]
        |> Req.new()
        |> Fuse.attach(options)

      :fuse.install(name, {{:standard, 1, 3000}, {:reset, 1000}})
      :fuse.melt(name)
      :fuse.melt(name)

      logs =
        capture_log([level: :warning], fn ->
          Req.request(req)
        end)

      assert logs == ""
    end

    test "emits a Telemetry events when a fuse is blown", %{name: name} do
      ref = :telemetry_test.attach_event_handlers(self(), [[:req_fuse, :blown]])

      req =
        [adapter: &TestAdapter.failed/1]
        |> Req.new()
        |> Fuse.attach(fuse_name: name)

      :fuse.install(name, {{:standard, 1, 3000}, {:reset, 1000}})
      :fuse.melt(name)
      :fuse.melt(name)

      capture_log(fn ->
        Req.request(req)
      end)

      assert_received {[:req_fuse, :blown], ^ref, _, %{fuse_name: ^name}}
    end

    test "does not emit a Telemetry events when a fuse closed", %{name: name} do
      ref = :telemetry_test.attach_event_handlers(self(), [[:req_fuse, :blown]])

      req =
        [adapter: &TestAdapter.failed/1, retry_delay: 100]
        |> Req.new()
        |> Fuse.attach(fuse_name: name)

      :fuse.install(name, {{:standard, 1, 3000}, {:reset, 1000}})
      :fuse.melt(name)

      capture_log(fn ->
        Req.request(req)
      end)

      refute_received {[:req_fuse, :blown], ^ref, _, %{fuse_name: ^name}}
    end
  end

  describe "melt?/1" do
    test "true for a status >= 500" do
      assert true == Fuse.melt?(%Req.Response{status: 599})
    end

    test "true for an exception" do
      assert true == Fuse.melt?(%{__exception__: true})
    end

    test "false for anything else" do
      assert false == Fuse.melt?(%{})
      assert false == Fuse.melt?(true)
      assert false == Fuse.melt?(false)
      assert false == Fuse.melt?("false")
    end
  end

  defmodule TestAdapter do
    @moduledoc "Mock adapter used for testing with `ReqFuse`"

    def success(request) do
      response = Req.Response.new(status: 200)
      {request, response}
    end

    def not_found(request) do
      response = Req.Response.new(status: 404)
      {request, response}
    end

    def failed(request) do
      response = Req.Response.new(status: 500)
      {request, response}
    end

    def exception(request) do
      {request, %RuntimeError{message: "something went wrong"}}
    end

    def closed(request) do
      {request, %Req.TransportError{reason: :closed}}
    end
  end
end
