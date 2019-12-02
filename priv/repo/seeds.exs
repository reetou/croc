# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# It is also run when you use `mix ecto.setup` or `mix ecto.reset`
#

users = [
  %{
    email: "jane.doe@example.com",
    password: "password",
    first_name: "Vladimir",
    last_name: "Sinitsyn"
  },
  %{
    email: "john.smith@example.org",
    password: "password",
    first_name: "Somer",
    last_name: "Hymphobus"
  }
]

for user <- users do
  {:ok, user} = Croc.Accounts.create_user(user)
  Croc.Accounts.confirm_user(user)
end
