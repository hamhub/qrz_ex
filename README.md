# QrzEx

QrzEx is an Elixir implementation of a QRZ.com client. It enables applications to make radio
callsign lookups and DXCC entity lookups using the QRZ.com XML API. The client takes care of
converting the XML responses into native Elixir maps for easy consumption.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `qrz_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:qrz_ex, "~> 0.1.0"}
  ]
end
```

## Usage

To use the QRZ.com API you must first retrieve a session key. This requires that you have a QRZ.com user
already. If you do not have a QRZ.com subscription you will still be able to use the API but will have limited
information returned on your queries and will be limited to 100 requests per day. For more information on the
subscriptions available, consult the [QRZ Subscriptions](https://shop.qrz.com/collections/subscriptions).

```elixir
QrzEx.login("CALLSIGN", "PASSWORD")
```

This will response like this:
```elixir
{:ok,
 %{
   count: 11,
   error: nil,
   expiration: "non-subscriber",
   key: "..."
 }}
```

Logging in provides you with a `key` which represents your logged in session. The expiration of a session
key is presently unknown and not clearly documented in the QRZ XML API documentation. Once you have this key
you can make other API calls:

```elixir
QrzEx.lookup_callsign("SESSION_KEY", "W1AW")
QrzEx.fetch_dxcc_entities("SESSION_KEY", 291)
QrzEx.fetch_dxcc_entities("SESSION_KEY", "W1AW")
QrzEx.fetch_dxcc_entities("SESSION_KEY")
```

The last example defaults to fetching all DXCC entities. Please use this sparingly so as to not overburden
the QRZ.com servers.



## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/qrz_ex](https://hexdocs.pm/qrz_ex).

