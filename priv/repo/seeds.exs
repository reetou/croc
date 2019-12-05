# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# It is also run when you use `mix ecto.setup` or `mix ecto.reset`
#

alias Croc.Repo.Games.Monopoly.Card

users = [
  %{
    email: "jane.doe@example.com",
    password: "password",
    username: "Vladimir"
  },
  %{
    email: "john.smith@example.org",
    password: "password",
    username: "Somer"
  }
]

for user <- users do
  {:ok, user} = Croc.Accounts.create_user(user)
  Croc.Accounts.confirm_user(user)
end
