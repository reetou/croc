defmodule Croc.Repo do
  use Ecto.Repo,
    otp_app: :croc,
    adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 10
end
