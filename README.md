# Überauth Fastmail [![Hex Version](https://img.shields.io/hexpm/v/ueberauth_fastmail.svg)](https://hex.pm/packages/ueberauth_fastmail)

> Fastmail OAuth2 strategy for Überauth.

## Installation

1. Setup your application in your Fastmail extension settings.

1. Add `:ueberauth_fastmail` to your list of dependencies in `mix.exs`:

   ```elixir
   def deps do
     [{:ueberauth_fastmail, "~> 0.2.0"}]
   end
   ```

1. Add Fastmail to your Überauth configuration:

   ```elixir
   config :ueberauth, Ueberauth,
     providers: [
       fastmail: {Ueberauth.Strategy.Fastmail, []}
     ]
   ```

1. Update your provider configuration:

   Use that if you want to read client ID/secret from the environment
   variables in the compile time:

   ```elixir
   config :ueberauth, Ueberauth.Strategy.Fastmail.OAuth,
     client_id: System.get_env("FASTMAIL_CLIENT_ID")
   ```

   Use that if you want to read client ID/secret from the environment
   variables in the run time:

   ```elixir
   config :ueberauth, Ueberauth.Strategy.Fastmail.OAuth,
     client_id: {System, :get_env, ["FASTMAIL_CLIENT_ID"]}
   ```

1. Include the Überauth plug in your controller:

   ```elixir
   defmodule MyApp.AuthController do
     use MyApp.Web, :controller
     plug Ueberauth
     ...
   end
   ```

1. Create the request and callback routes if you haven't already:

   ```elixir
   scope "/auth", MyApp do
     pipe_through :browser

     get "/:provider", AuthController, :request
     get "/:provider/callback", AuthController, :callback
   end
   ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/fastmail

## License

Please see [LICENSE](https://github.com/svycal/ueberauth_fastmail/blob/main/LICENSE.md) for licensing details.
