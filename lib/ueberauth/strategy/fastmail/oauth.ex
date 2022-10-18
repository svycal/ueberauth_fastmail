defmodule Ueberauth.Strategy.Fastmail.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Fastmail.

  To add your `client_id` include this value in your configuration.

      config :ueberauth, Ueberauth.Strategy.Fastmail.OAuth,
        client_id: System.get_env("FASTMAIL_CLIENT_ID")
  """
  use OAuth2.Strategy

  alias Ueberauth.Strategy.Fastmail.OAuthStrategy

  @behaviour OAuthStrategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.fastmail.com",
    authorize_url: "https://api.fastmail.com/oauth/authorize",
    token_url: "https://api.fastmail.com/oauth/refresh"
  ]

  # Public API

  @doc """
  Construct a client for requests to Fastmail.

  This will be setup automatically for you in `Ueberauth.Strategy.Fastmail`.

  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  @impl OAuthStrategy
  def client(opts \\ []) do
    config = Application.get_env(:ueberauth, __MODULE__, [])
    opts = @defaults |> Keyword.merge(opts) |> Keyword.merge(config) |> resolve_values()
    json_library = Ueberauth.json_library()

    opts
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  @impl OAuthStrategy
  def authorize_url!(params \\ [], opts \\ []) do
    OAuth2.Client.authorize_url!(client(opts), params)
  end

  @doc """
  Fetches a token.
  """
  @impl OAuthStrategy
  def get_token(params \\ [], opts \\ []) do
    OAuth2.Client.get_token(client(opts), params)
  end

  @doc """
  Makes a GET request to the given URL.
  """
  @impl OAuthStrategy
  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client()
    |> OAuth2.Client.get(url, headers, opts)
  end

  # Strategy Callbacks

  @impl OAuth2.Strategy
  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  @impl OAuth2.Strategy
  def get_token(client, params, headers) do
    client
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
    |> put_header("authorization", "Basic " <> Base.encode64(client.client_secret <> ":"))
  end

  defp resolve_values(list) do
    for {key, value} <- list do
      {key, resolve_value(value)}
    end
  end

  defp resolve_value({m, f, a}) when is_atom(m) and is_atom(f), do: apply(m, f, a)
  defp resolve_value(v), do: v
end
