defmodule QrzEx do
  use Tesla
  import SweetXml

  plug(Tesla.Middleware.BaseUrl, "http://xmldata.qrz.com/xml/current")

  # Public API

  def login(username, password) do
    case get("/", query: [username: username, password: password]) do
      {:ok, %{body: body}} ->
        body
        |> get_session()
        |> process_login()

      _ ->
        {:error, :server_error}
    end
  end

  def lookup_callsign(session_key, callsign) do
    case get("/", query: [s: session_key, callsign: callsign]) do
      {:ok, %{body: body}} ->
        session = get_session(body)
        callsign = get_callsign(body)
        process_lookup(session, callsign)

      _ ->
        {:error, :server_error}
    end
  end

  def fetch_dxcc_entities(session_key, entity_key \\ "all") do
    case get("/", query: [s: session_key, dxcc: entity_key]) do
      {:ok, %{body: body}} ->
        session = get_session(body)
        entities = get_dxcc_entites(body)
        process_entities(session, entities)

      _ ->
        {:error, :server_error}
    end
  end

  # Helper functions.

  def get_session(body),
    do:
      xpath(body, ~x"//QRZDatabase/Session"e,
        error: ~x"./Error/text()",
        key: ~x"./Key/text()"s,
        count: ~x"./Count/text()"s,
        expiration: ~x"./SubExp/text()"s,
        message: ~x"./Message/text()"s
      )

  def get_callsign(body),
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

  def get_dxcc_entites(body),
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

  def process_login(session) do
    cond do
      session.error == nil -> {:ok, session}
      true -> {:error, :invalid, session}
    end
  end

  def process_lookup(session, callsign) do
    cond do
      session.error == nil ->
        {:ok, %{session: session, callsign: callsign}}

      true ->
        {:error, :invalid, session}
    end
  end

  def process_entities(session, entities) do
    cond do
      session.error == nil ->
        {:ok, %{session: session, dxcc_entities: entities}}

      true ->
        {:error, :invalid, session}
    end
  end
end
