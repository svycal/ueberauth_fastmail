import Config

config :ueberauth, Ueberauth,
  providers: [
    fastmail:
      {Ueberauth.Strategy.Fastmail,
       [
         oauth2_module: OAuthMock
       ]}
  ]
