defmodule CrocWeb.AuthTestHelpers do
  use Phoenix.ConnTest

  import Ecto.Changeset

  alias Croc.{Accounts, Repo, Sessions}
  alias CrocWeb.Auth.Token
  alias CrocWeb.Auth.Token

  def add_user(email) do
    user = %{email: email, password: "reallyHard2gue$$"}
    {:ok, user} = Accounts.create_user(user)
    user
  end

  def gen_key(email), do: Token.sign(%{"email" => email})

  def add_user_confirmed(email) do
    email
    |> add_user()
    |> change(%{confirmed_at: now()})
    |> Repo.update!()
  end

  def add_reset_user(email) do
    email
    |> add_user()
    |> change(%{confirmed_at: now()})
    |> change(%{reset_sent_at: now()})
    |> Repo.update!()
  end

  def add_token_conn(conn, user) do
    {:ok, %{id: session_id}} = Sessions.create_session(%{user_id: user.id})
    user_token = Token.sign(%{"session_id" => session_id})

    conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", user_token)
  end

  defp now do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end
end
