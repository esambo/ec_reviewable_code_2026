defmodule Wordler.Repo do
  use Ecto.Repo,
    otp_app: :wordler,
    adapter: Ecto.Adapters.Postgres
end
