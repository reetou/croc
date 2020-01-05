defmodule CrocWeb.AuthTestHelpers do
  use Phoenix.ConnTest

  import Ecto.Changeset

  alias Croc.{
    Accounts,
    Repo,
    Sessions,
    Accounts.User
  }
  alias CrocWeb.Auth.Token
  alias CrocWeb.Auth.Token

  def add_user(email) do
    user = %{email: email, password: "reallyHard2gue$$", username: email <> "_username"}
    {:ok, user} = Accounts.create_user(user)
    user
  end

  def gen_key(email), do: Token.sign(%{"email" => email})

  def add_vk_user(vk_id) do
    user = %{ first_name: "Вова", last_name: "Синицкий", vk_id: vk_id }
    %User{} = user = Accounts.create_vk_user(%User{}, user)
    user
  end

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

  def add_session(conn, user) do
    {:ok, %{id: session_id}} = Sessions.create_session(%{user_id: user.id})

    conn
    |> put_session(:phauxth_session_id, session_id)
    |> configure_session(renew: true)
  end
end
