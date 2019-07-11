defmodule QrzEx do
  @moduledoc """
  Provides an easy to use Elixir API for looking up amateur radio callsigns
  and DXCC entity information from the QRZ.com XML API.
  """
  import SweetXml

  @typedoc """
  Represents information about the session. 

  This is returned on every request.

  See _the Session Node_ on the [QRZ XML API](https://www.qrz.com/XML/current_spec.html).
  """
  @type session() :: %{
          error: String.t(),
          key: String.t(),
          count: String.t(),
          expiration: String.t(),
          message: String.t()
        }

  @typedoc """
  Represents information about a callsign. 

  See _Callsign Lookups_ on the [QRZ XML API](https://www.qrz.com/XML/current_spec.html).
  """
  @type callsign() :: %{
          callsign: String.t(),
          xref_callsign: String.t(),
          previous_callsign: String.t(),
          aliases: String.t(),
          license_class: String.t(),
          license_codes: String.t(),
          license_eff_dt: String.t(),
          license_exp_dt: String.t(),
          first_name: String.t(),
          last_name: String.t(),
          born: String.t(),
          address: String.t(),
          city: String.t(),
          state: String.t(),
          country: String.t(),
          email: String.t(),
          callsign_entity_id: String.t(),
          callsign_entity_name: String.t(),
          mailing_entity_id: String.t(),
          lat: String.t(),
          long: String.t(),
          grid: String.t(),
          fips: String.t(),
          cq_zone: String.t(),
          itu_zone: String.t(),
          geoloc: String.t(),
          eqsl: String.t(),
          mqsl: String.t(),
          lotw: String.t(),
          bio: String.t(),
          biodate: String.t()
        }
  @typedoc """
  Represents information about a DXCC entity. 

  See _DXCC / Prefix Lookups_ on the [QRZ XML API](https://www.qrz.com/XML/current_spec.html).
  """
  @type dxcc_entity() :: %{
          entity_id: String.t(),
          country_code: String.t(),
          country_code_full: String.t(),
          country_name: String.t(),
          continent: String.t(),
          itu_zone: String.t(),
          cq_zone: String.t(),
          timezone: String.t(),
          lat: String.t(),
          long: String.t()
        }

  # Public API

  @doc """
  Fetches a session key from the QRZ XML API.

  ## Parameters

    - username: String containing your username (typically your callsign).
    - password: String containing your QRZ password.

  ## Example

  ```
  {:ok, session} = QrzEx.login("CALLSIGN", "password") 
  ```
  """
  @spec login(String.t(), String.t()) ::
          {:ok, %{session: session()}}
          | {:error, :invalid, %{session: session()}}
          | {:error, :server_error}
  def login(username, password) do
    case Tesla.get(client(), "/", query: [username: username, password: password]) do
      {:ok, %{body: body}} ->
        body
        |> get_session()
        |> process_login()

      _ ->
        {:error, :server_error}
    end
  end

  @doc """
  Looks up an amateur radio callsign from the QRZ XML API.

  ## Parameters

    - session: This will either be a strinc containing your session key or the session map return by `login/2`.
    - callsign: String containing the callsign you want to look up.
  """
  @spec lookup_callsign(String.t() | map(), String.t()) ::
          {:ok, %{session: session(), callsign: callsign()}}
          | {:error, :invalid, %{session: session()}}
          | {:error, :server_error}
          | {:error, :bad_session}
  def lookup_callsign(%{error: nil, key: session_key}, callsign),
    do: lookup_callsign(session_key, callsign)

  def lookup_callsign(session, _callsign) when is_map(session), do: {:error, :bad_session}

  def lookup_callsign(session_key, callsign) when session_key do
    case Tesla.get(client(), "/", query: [s: session_key, callsign: callsign]) do
      {:ok, %{body: body}} ->
        session = get_session(body)
        callsign = get_callsign(body)
        process_lookup(session, callsign)

      _ ->
        {:error, :server_error}
    end
  end

  @doc """
  Looks up an amateur radio callsign from the QRZ XML API.

  ## Parameters

    - session_key: String your session key (see `login/2`).
    - entity_key: A value you want to use for looking an entity.

  The `entity_key` can be an integer referencing an entity ID such as `291`, it
  can be a callsign such as `"W1AW"`, or it can be the keyword `"all"`, which
  is the default.

  The `"all"` entity key will return a list of all current DXCC entities.
  """
  @spec fetch_dxcc_entities(String.t(), any()) ::
          {:ok, %{session: session(), dxcc_entities: list(dxcc_entity())}}
          | {:error, :invalid, %{session: session()}}
          | {:error, :server_error}
  def fetch_dxcc_entities(session_key, entity_key \\ "all") do
    case Tesla.get(client(), "/", query: [s: session_key, dxcc: entity_key]) do
      {:ok, %{body: body}} ->
        session = get_session(body)
        entities = get_dxcc_entites(body)
        process_entities(session, entities)

      _ ->
        {:error, :server_error}
    end
  end

  # Helper functions.

  defp get_session(body),
    do:
      xpath(body, ~x"//QRZDatabase/Session"e,
        error: ~x"./Error/text()",
        key: ~x"./Key/text()"s,
        count: ~x"./Count/text()"s,
        expiration: ~x"./SubExp/text()"s,
        message: ~x"./Message/text()"s
      )

  defp get_callsign(body),
    do:
      xpath(body, ~x"//QRZDatabase/Callsign"e,
        callsign: ~x"./call/text()"s,
        xref_callsign: ~x"./xref/text()"s,
        previous_callsign: ~x"./p_call/text()"s,
        aliases: ~x"./aliases/text()"s,
        license_class: ~x"./class/text()"s,
        license_codes: ~x"./codes/text()"s,
        license_eff_dt: ~x"./efdate/text()"s,
        license_exp_dt: ~x"./expdate/text()"s,
        first_name: ~x"./fname/text()"s,
        last_name: ~x"./name/text()"s,
        born: ~x"./born/text()"s,
        address: ~x"./addr1/text()"s,
        city: ~x"./addr2/text()"s,
        state: ~x"./state/text()"s,
        country: ~x"./country/text()"s,
        email: ~x"./email/text()"s,
        callsign_entity_id: ~x"./dxcc/text()"s,
        callsign_entity_name: ~x"./land/text()"s,
        mailing_entity_id: ~x"./ccode/text()"s,
        lat: ~x"./lat/text()"s,
        long: ~x"./long/text()"s,
        grid: ~x"./grid/text()"s,
        fips: ~x"./fips/text()"s,
        cq_zone: ~x"./cqzone/text()"s,
        itu_zone: ~x"./ituzone/text()"s,
        geoloc: ~x"./geoloc/text()"s,
        eqsl: ~x"./esql/text()"s,
        mqsl: ~x"./mqsl/text()"s,
        lotw: ~x"./lotw/text()"s,
        bio: ~x"./bio/text()"s,
        biodate: ~x"./biodate/text()"s
      )

  defp get_dxcc_entites(body),
    do:
      xpath(body, ~x"//QRZDatabase/DXCC"l,
        entity_id: ~x"./dxcc/text()"s,
        country_code: ~x"./cc/text()"s,
        country_code_full: ~x"./ccc/text()"s,
        country_name: ~x"./name/text()"s,
        continent: ~x"./continent/text()"s,
        itu_zone: ~x"./ituzone/text()"s,
        cq_zone: ~x"./cqzone/text()"s,
        timezone: ~x"./timezone/text()"s,
        lat: ~x"./lat/text()"s,
        long: ~x"./long/text()"s
      )

  defp process_login(session) do
    cond do
      session.error == nil -> {:ok, session}
      true -> {:error, :invalid, session}
    end
  end

  defp process_lookup(session, callsign) do
    cond do
      session.error == nil ->
        {:ok, %{session: session, callsign: callsign}}

      true ->
        {:error, :invalid, session}
    end
  end

  defp process_entities(session, entities) do
    cond do
      session.error == nil ->
        {:ok, %{session: session, dxcc_entities: entities}}

      true ->
        {:error, :invalid, session}
    end
  end

  defp client(),
    do: Tesla.client([{Tesla.Middleware.BaseUrl, "http://xmldata.qrz.com/xml/current"}])
end
