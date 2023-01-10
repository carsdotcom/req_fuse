# ReqFuse

<object data="assets/logo.png" type="image/jpeg">
  <img src="assets/fuse.png" alt="ReqFuse fuses" />
</object>

ReqFuse on Github https://github.com/carsdotcom/req_fuse

ReqFuse on Hex https://hex.pm/req_fuse

ReqFuse on HexDocs https://hexdocs.pm/req_fuse

[![CI](https://github.com/carsdotcom/req_fuse/actions/workflows/elixir.yml/badge.svg)](https://github.com/carsdotcom/req_fuse/actions/workflows/elixir.yml)


<!-- MDOC -->

[Req](https://github.com/wojtekmach/req) plugin for [`:fuse`](https://github.com/jlouis/fuse)

ReqFuse provides circuit-breaking functionality for HTTP requests that use the Req library.

## Usage

After adding the dependencies, simply attach the ReqFuse step to your request ensuring
you are passing in the required and any optional fuse configuration.

```elixir
Mix.install([
  {:req, "~> 0.3"},
  {:req_fuse, "~> 0.2"}
])

req_fuse_opts = [fuse_name: My.Example.Fuse]
req = [url: "https://httpstat.us/500", retry: :never]
|> Req.new()
|> ReqFuse.attach(req_fuse_opts)

# Fire the request enough times to melt the fuse
Enum.each(0..10, fn _ -> Req.request(req) end)
  => :ok
Req.request(req)
  => 08:45:42.518 [warning] :fuse circuit breaker is open; fuse = Elixir.My.Example.Fuse
  => {:error, %RuntimeError{message: "circuit breaker is open"}}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `req_fuse` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:req_fuse, ">= 0.2.0"}
  ]
end
```

<!-- MDOC -->

## License

  See [LICENSE](https://github.com/carsdotcom/req_fuse/blob/main/LICENSE)

## Updates

  See [CHANGELOG.md](https://github.com/carsdotcim/req_fuse/blob/main/CHANGELOG.md)

  Updating the changelog. (Uses `auto-changelog`)
  https://github.com/cookpete/auto-changelog

  `auto-changelog --breaking-pattern "BREAKING CHANGE" --template keepachangelog  --commit-limit false --unreleased`

### Tagging by version in mix.exs

  ```
    git tag `grep -e '@version \"\d\.\d\.\d\".*' mix.exs | awk '{gsub(/"/, "", $2); print $2}'`
  ```
