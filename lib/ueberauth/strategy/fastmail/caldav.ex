defmodule Ueberauth.Strategy.Fastmail.CalDAV do
  @moduledoc """
  A client for communicating with Fastmail service.
  """

  require Logger
  import SweetXml

  @current_user_principal_xpath ~x"//d:multistatus/d:response/d:propstat/d:prop/d:current-user-principal/d:href/text()"s
  @current_user_email_xpath ~x"//d:multistatus/d:response/d:propstat/d:prop/c:calendar-user-address-set/d:href/text()"s
  @current_user_displayname_xpath ~x"//d:multistatus/d:response/d:propstat/d:prop/d:displayname/text()"s

  @doc """
  Finds the user's email address and display name
  """
  def get_user(token) do
    client = build_xml_client(token)

    with {:ok, principal_href} <- fetch_current_user_principal(client),
         {:ok, %{email: email, display_name: display_name}} <-
           fetch_user_props(client, principal_href) do
      {:ok,
       %{
         email: email,
         display_name: display_name
       }}
    end
  end

  # Private helpers

  defp build_xml_client(%OAuth2.AccessToken{access_token: token}) do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, "https://caldav.fastmail.com"},
      {Tesla.Middleware.BearerAuth, token: token},
      {Tesla.Middleware.Headers,
       [
         {"content-type", "application/xml; charset=\"utf-8\""},
         {"prefer", "return-minimal"}
       ]},
      Tesla.Middleware.ContentLength,
      Tesla.Middleware.ConditionalDebugLogger,
      Tesla.Middleware.KeepRequest,
      Tesla.Middleware.Telemetry,
      Tesla.Middleware.PathParams
    ])
  end

  defp fetch_current_user_principal(client) do
    body = """
      <d:propfind xmlns:d="DAV:">
        <d:prop>
          <d:current-user-principal />
        </d:prop>
      </d:propfind>
    """

    opts = [
      method: :propfind,
      url: "/dav/calendars",
      body: body,
      opts: [template_url: "https://caldav.fastmail.com/:current_user_principal"]
    ]

    case Tesla.request(client, opts) do
      {:ok, %{status: 207, body: body}} ->
        root = parse_xml(body)
        value = root |> xpath(@current_user_principal_xpath) |> to_string()
        {:ok, value}

      err ->
        handle_failure(err)
    end
  end

  defp fetch_user_props(client, url) do
    body = """
      <d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
        <d:prop>
          <d:displayname />
          <c:calendar-user-address-set />
        </d:prop>
      </d:propfind>
    """

    opts = [
      method: :propfind,
      url: url,
      body: body
    ]

    case Tesla.request(client, opts) do
      {:ok, %{status: 207, body: body}} ->
        root = parse_xml(body)
        email = root |> xpath(@current_user_email_xpath) |> to_string()
        display_name = root |> xpath(@current_user_displayname_xpath) |> to_string()

        {:ok,
         %{
           email: email,
           display_name: display_name
         }}

      err ->
        handle_failure(err)
    end
  end

  defp parse_xml(xml) do
    {:ok, root} = Saxmerl.parse_string(xml, dynamic_atoms: true)
    root
  end

  defp handle_failure({:ok, %{status: 401}}) do
    {:error, :unauthorized}
  end

  defp handle_failure({:ok, %{status: 404}}) do
    {:error, :not_found}
  end

  defp handle_failure(_) do
    {:error, :request_failed}
  end
end
