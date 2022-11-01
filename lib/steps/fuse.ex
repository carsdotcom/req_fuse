defmodule ReqFuse.Steps.Fuse do
  @moduledoc """
  Configure circuit-breaker via `:fuse`.
  """

  require Logger

  @defaults {
    {:standard, 10, 10_000},
    {:reset, 30_000}
  }

  @fuse_keys [
      :fuse_melt_func,
      :fuse_mode,
      :fuse_name,
      :fuse_opts,
      :fuse_verbose
    ]

  @doc """
  Attach circuit-breaker :fuse step.

  ## Fuse Options

    - `:fuse_melt_func` - function to determine if response should melt the fuse
      defaults to `melt?/1`
    - `:fuse_mode` - how to query the fuse, which has two values:
      - `:sync` - queries are serialized through the `:fuse_server` process (the default)
      - `:async_dirty` - queries check the fuse state directly, but may not account for recent melts or resets
    - `:fuse_name` - **REQUIRED** the name of the fuse to install
    - `:fuse_opts` The fuse options (see fuse docs for reference) (order matters)
      defaults to `#{inspect(@defaults)}`.
      See `defaults/0` for more information.
    - `:fuse_verbose` - If false, suppress Log output

  See https://github.com/jlouis/fuse#tutorial for more information about the supported fuse
  strategies and their options.

  ### Melt function

  By default ReqFuse will send a melt message to your fuse server for any request where the status is over 500.

  There are many other melt options. The melt_function must be a 1-arity function that evaluates the
  response. Pass the function reference in the `:fuse_melt_func` key as `&Mod.fn/arity` (or MFA notation).

  Any melt function should be widely permissive of what it will evaluate.

  In addition to a `%Req.Response{}` it could receive other error state messages from the underlying
  HTTP adapter libraries. For example:

    - {:error, %Mint.TransportError{reason: :econnrefused}}
    - {:error, %Mint.TransportError{reason: :timeout}}
    - {:error, %HTTPoison{}}
    - some_other_flavor_of_error
    - etc

  ## Example `melt?/1` function
  ```elixir
    def melt?(%Req.Response{} = response) do
      cond do
        response.status in [408, 429] -> true
        response.status >= 200 and response.status < 300 -> false
        response.status < 200 -> true
    end
    def melt?(%Req.Response{}),  do: false
    def melt?(error_response), do: true
  ```

  ## Options Example
  ```elixir
    [
      fuse_melt_func: &__MODULE__.my_melt_function/1,
      fuse_mode: :sync,
      fuse_name: My.Fuse.Name,
      fuse_opts: {{:standard, 1, 1000}, {:reset, 300}},
      fuse_verbose: true
    ]
  ```
  """
  @spec attach(Req.Request.t(), keyword()) :: Req.Request.t()
  def attach(%Req.Request{} = request, options) do
    _ = Keyword.fetch!(options, :fuse_name)
    request
    |> Req.Request.register_options(@fuse_keys)
    |> Req.Request.merge_options(options)
    |> Req.Request.prepend_request_steps(fuse: &check_fuse_state/1)
    |> Req.Request.prepend_response_steps(fuse: &melt_fuse/1)
  end

  @doc """
  Reasonalble (hopefully) fuse defaults, based on the fuse docs: `#{inspect(@defaults)}`.

  - `fuse type`
    - `first tuple` - Specify the fuse strategy (:standard or :fault_injection),

      - :standard, permit N (3) failures in  M (10_000) milliseconds
        - `{:standard, N, M}`
        - `{:standard, 3, 10_000}`
      - :fault_injection, This fuse type sets up a fault injection scheme where the
          fuse fails at rate R (0.005), N (3) and M (10_000) work similar to :standard.
          e.g. `{:fault_injection, 0.005, 3, 10_000}`
        - `{:fault_injection, R, N, M}`
          (Inject one fault for 0.5% of requests, 3 failures in 10 seconds melts the fuse)
    - `second tuple` - Specify the recover period in milliseconds
        e.g. `{:reset, 30_000}` unmelt the fuse after 30 seconds.
      - `{:reset, 30_000}`
  """
  def defaults, do: @defaults

  defp check_fuse_state(request) do
    name = request.options.fuse_name
    mode = Map.get(request.options, :fuse_mode, :sync)
    opts = Map.get(request.options, :fuse_opts, @defaults)
    verbose = Map.get(request.options, :fuse_verbose, true)

    case :fuse.ask(name, mode) do
      :ok ->
        request

      :blown ->
        if verbose do
          Logger.warning(":fuse circuit breaker is open; fuse = #{name}")
        end

        {Req.Request.halt(request), RuntimeError.exception("circuit breaker is open")}

      {:error, :not_found} ->
        _ = :fuse.install(name, opts)
        request
    end
  end

  defp melt_fuse({request, response}) do
    name = request.options.fuse_name
    melt_func = Map.get(request.options, :fuse_melt_func, &melt?/1)

    if melt_func.(response) do
      :fuse.melt(name)
    end

    {request, response}
  end

  @doc """
  A default :fuse melt test.
  """
  @spec melt?(term()) :: boolean()
  def melt?(%Req.Response{} = response) when response.status >= 500, do: true
  def melt?(_), do: false
end
