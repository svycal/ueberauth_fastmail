defmodule Ueberauth.Strategy.Fastmail do
  @moduledoc """
  Fastmail Strategy for Überauth.
  """

  use Ueberauth.Strategy,
    default_scope: "read_only",
    oauth2_module: Ueberauth.Strategy.Fastmail.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the Fastmail authentication page.
  """
  def handle_request!(conn) do
    params = [] |> with_scope(conn) |> with_state_param(conn)
    opts = [redirect_uri: callback_url(conn)]
    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [params, opts]))
  end

  @doc """
  Handles the callback from Fastmail.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    params = [code: code]
    module = option(conn, :oauth2_module)
    opts = [redirect_uri: callback_url(conn)]

    case apply(module, :get_token, [params, opts]) do
      {:ok, %{token: %OAuth2.AccessToken{} = token}} ->
        conn
        |> put_private(:fastmail_token, token)
        |> fetch_user(token)

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
  Fetches the uid field from the response.
  """
  def uid(conn) do
    raise "Not implemented"
    # conn.private.stripe_user["id"]
  end

  @doc """
  Includes the credentials from the Fastmail response.
  """
  def credentials(conn) do
    raise "Not implemented"
    # token = conn.private.fastmail_token
    # scope_string = token.other_params["scope"] || ""
    # scopes = String.split(scope_string, " ")

    # %Credentials{
    #   expires: !!token.expires_at,
    #   expires_at: token.expires_at,
    #   scopes: scopes,
    #   token_type: Map.get(token, :token_type),
    #   refresh_token: token.refresh_token,
    #   token: token.access_token,
    #   other: %{
    #     livemode: token.other_params["livemode"],
    #     stripe_user_id: token.other_params["stripe_user_id"],
    #     stripe_publishable_key: token.other_params["stripe_publishable_key"]
    #   }
    # }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    raise "Not implemented"
    # user = conn.private.stripe_user

    # %Info{
    #   email: user["email"],
    #   name:
    #     user
    #     |> Map.get("settings", %{})
    #     |> Map.get("dashboard", %{})
    #     |> Map.get("display_name", nil)
    # }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Fastmail callback.
  """
  def extra(conn) do
    raise "Not implemented"
    # %Extra{
    #   raw_info: %{
    #     token: conn.private.stripe_token,
    #     user: conn.private.stripe_user
    #   }
    # }
  end

  # API Requests

  defp fetch_user(conn, token) do
    raise "Not implemented"
    # module = option(conn, :oauth2_module)
    # account_id = token.other_params["stripe_user_id"]

    # case apply(module, :get, [
    #        token,
    #        "/v1/accounts/#{account_id}",
    #        [{"stripe-version", "2020-03-02"}]
    #      ]) do
    #   {:ok, %{status_code: 200, body: user}} ->
    #     put_private(conn, :fastmail_user, user)

    #   err ->
    #     handle_failure(conn, err)
    # end
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

  # Private helpers

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp with_scope(opts, conn) do
    scope = conn.params["scope"] || option(conn, :default_scope)
    Keyword.put(opts, :scope, scope)
  end
end
