defmodule Croc.Repo do
  use Ecto.Repo,
    otp_app: :croc,
    adapter: Ecto.Adapters.Postgres
end
