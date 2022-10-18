defmodule Ueberauth.Strategy.Fastmail.OAuthStrategy do
  @moduledoc false

  alias OAuth2.Client

  @callback client(Keyword.t()) :: Client.t()
  @callback authorize_url!(Client.params(), list()) :: binary()
  @callback get_token(Client.params(), opts :: Keyword.t()) ::
              {:ok, Client.t()} | {:error, OAuth2.Response.t()} | {:error, term()}
  @callback get(Client.t(), url :: String.t(), Client.headers(), opts :: Keyword.t()) ::
              {:ok, Client.t()} | {:error, OAuth2.Response.t()} | {:error, term()}
end
