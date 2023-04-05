defmodule Ueberauth.Strategy.Fastmail do
  @moduledoc """
  Fastmail Strategy for Überauth.
  """

  use Ueberauth.Strategy,
    default_scope: "https://www.fastmail.com/dev/protocol-caldav",
    oauth2_module: Ueberauth.Strategy.Fastmail.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra
  alias Ueberauth.Strategy.Fastmail.CalDAV

  @doc """
  Handles the initial redirect to the Fastmail authentication page.
  """
  def handle_request!(conn) do
    {params, conn} =
      []
      |> with_scope(conn)
      |> with_state_param(conn)
      |> with_pkce_param(conn)

    opts = [redirect_uri: callback_url(conn)]
    module = option(conn, :oauth2_module)

    conn
    |> redirect!(module.authorize_url!(params, opts))
  end

  @doc """
  Handles the callback from Fastmail.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    verifier = conn.cookies["fastmail_verifier"]

    params = [
      grant_type: "authorization_code",
      code: code,
      code_verifier: verifier,
      redirect_uri: callback_url(conn)
    ]

    module = option(conn, :oauth2_module)
    opts = [redirect_uri: callback_url(conn)]

    case module.get_token(params, opts) do
      {:ok, %{token: %OAuth2.AccessToken{access_token: "" <> _string} = token}} ->
        conn
        |> put_private(:fastmail_token, token)
        |> fetch_user()

      err ->
        handle_failure(conn, err)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:fastmail_user, nil)
    |> put_private(:fastmail_token, nil)
  end

  @doc """
  Includes the credentials from the Fastmail response.
  """
  def credentials(conn) do
    token = conn.private.fastmail_token
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, " ")

    %Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: scopes,
      token_type: Map.get(token, :token_type),
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  def fetch_user(conn) do
    case CalDAV.get_user(conn.private.fastmail_token) do
      {:ok, user} ->
        email =
          case user[:email] do
            "mailto:" <> e -> e
            e -> e
          end

        display_name = user[:display_name]

        conn
        |> put_private(:fastmail_email, email)
        |> put_private(:fastmail_name, display_name)

      {:error, _} ->
        conn
    end
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    %Info{
      email: conn.private.fastmail_email,
      name: conn.private.fastmail_name
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Fastmail callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.fastmail_token
      }
    }
  end

  # Request failure handling

  defp handle_failure(conn, {:error, %OAuth2.Error{reason: reason}}) do
    set_errors!(conn, [error("OAuth2", reason)])
  end

  defp handle_failure(conn, {:error, %OAuth2.Response{status_code: 401}}) do
    set_errors!(conn, [error("token", "unauthorized")])
  end

  defp handle_failure(
         conn,
         {:error, %OAuth2.Response{body: %{"code" => code, "message" => message}}}
       ) do
    set_errors!(conn, [error("error_code_#{code}", "#{message} (#{code})")])
  end

  defp handle_failure(conn, {:error, %OAuth2.Response{status_code: status_code}}) do
    set_errors!(conn, [error("http_status_#{status_code}", "")])
  end

  defp handle_failure(
         conn,
         {:ok,
          %OAuth2.Client{
            token: %OAuth2.AccessToken{
              other_params: %{
                "error" => error_type,
                "error_description" => error_description
              }
            }
          }}
       ) do
    set_errors!(conn, [
      error(error_type, error_description)
    ])
  end

  # Private helpers

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp with_scope(opts, conn) do
    scope = conn.params["scope"] || option(conn, :default_scope)
    Keyword.put(opts, :scope, scope)
  end

  defp with_pkce_param(params, conn) do
    {verifier, challenge} = generate_pkce_challenge()

    conn = Plug.Conn.put_resp_cookie(conn, "fastmail_verifier", verifier, max_age: 60 * 10)

    {params
     |> Keyword.put(:code_challenge_method, "S256")
     |> Keyword.put(:code_challenge, challenge), conn}
  end

  # This generates a cryptographically random string for use in a PKCE
  # challenge. This isn't quite perfect as it only uses 64 characters out of a
  # possible 66, but it's good enough for our purposes.
  #
  # See https://tools.ietf.org/html/rfc7636#section-4.1
  defp generate_pkce_challenge do
    verifier =
      :crypto.strong_rand_bytes(80)
      |> Base.url_encode64()
      |> String.trim_trailing("=")

    challenge =
      :crypto.hash(:sha256, verifier)
      |> Base.url_encode64()
      |> String.trim_trailing("=")

    {verifier, challenge}
  end
end
