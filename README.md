# ReqFuse

<object data="assets/logo.png" type="image/jpeg">
  <img src="assets/fuse.png" alt="ReqFuse fuses" />
</object>

ReqFuse on Github https://github.com/carsdotcom/req_fuse

ReqFuse on Hex https://hex.pm/req_fuse

ReqFuse on HexDocs https://hexdocs.pm/req_fuse

<!-- MDOC -->

[Req](https://github.com/wojtekmach/req) plugin for [`:fuse`](https://github.com/jlouis/fuse)


## Usage

After adding the dependency, simply attach the Fuse step to your request.
Then ensure you are passing in the required and eny optional fuse configurations.

```elixir
Mix.install([
  {:req, "~> 0.3.0"},
  {:req_fuse, "~> 0.1.0"}
])

# OR

opts = [fuse_name: My.Example.Fuse]
req = Req.new(url: "https://httpstat.us/500", retry: :never)
req = ReqFuse.attach(req, opts)

# Fire the request enough times to melt the fuse
Enum.each(0..10, fn _ -> Req.request(req) end)
  => :ok
Req.request(req)
  => 08:45:42.518 [warning] :fuse circuit breaker is open; fuse = Elixir.My.Example.Fuse
  => {:error, %RuntimeError{message: "circuit breaker is open"}}
```

<!-- MDOC -->

## Updates

  See [CHANGELOG.md](https://github.com/carsdotcim/req_fuse/blob/main/CHANGELOG.md)

  Updating the changelog. (Uses `auto-changelog`)
  https://github.com/cookpete/auto-changelog

  `auto-changelog --breaking-pattern "BREAKING CHANGE" --template keepachangelog  --commit-limit false --unreleased`

### Tagging by version in mix.exs

  ```
    git tag `grep -e '@version \"\d\.\d\.\d\".*' mix.exs | awk '{gsub(/"/, "", $2); print $2}'`
  ```
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `req_fuse` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:req_fuse, ">= 0.1.0"}
  ]
end
```

## License

  See [LICENSE](https://github.com/carsdotcom/req_fuse/blob/main/LICENSE)

