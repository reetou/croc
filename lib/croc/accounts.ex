defmodule Croc.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias Croc.{Accounts.User, Repo, Sessions, Sessions.Session}
  alias Croc.Repo.Games.Monopoly.{
    EventCard,
    UserEventCard,
  }

  @type changeset_error :: {:error, Ecto.Changeset.t()}

  @doc """
  Returns the list of users.
  """
  @spec list_users() :: [User.t()]
  def list_users, do: Repo.all(User)

  @doc """
  Gets a single user.
  """
  @spec get_user!(integer) :: User.t() | no_return
  def get_user!(id), do: Repo.get!(User, id)
  @spec get_user(integer) :: User.t() | nil
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a user based on the params.

  This is used by Phauxth to get user information.
  """
  @spec get_by(map) :: User.t() | nil
  def get_by(%{"session_id" => session_id}) do
    with %Session{user_id: user_id} <- Sessions.get_session(session_id),
         do: Repo.get(User, user_id)
  end

  def get_by(%{"email" => email}) do
    Repo.get_by(User, email: email)
  end

  def get_by(%{"id" => id}) do
    Repo.get_by(User, id: id)
  end

  @doc """
  Creates a user.
  """
  @spec create_user(map) :: {:ok, User.t()} | changeset_error
  def create_user(attrs) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  @spec update_user(User.t(), map) :: {:ok, User.t()} | changeset_error
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  @spec delete_user(User.t()) :: {:ok, User.t()} | changeset_error
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  @spec change_user(User.t()) :: Ecto.Changeset.t()
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  @doc """
  Confirms a user's email.
  """
  @spec confirm_user(User.t()) :: {:ok, User.t()} | changeset_error
  def confirm_user(%User{} = user) do
    user
    |> User.confirm_changeset(DateTime.truncate(DateTime.utc_now(), :second))
    |> Repo.update()
  end

  @doc """
  Makes a password reset request.
  """
  @spec create_password_reset(map) :: {:ok, User.t()} | nil
  def create_password_reset(attrs) do
    with %User{} = user <- get_by(attrs) do
      user
      |> User.password_reset_changeset(DateTime.truncate(DateTime.utc_now(), :second))
      |> Repo.update()
    end
  end

  def add_exp(id, exp) when is_integer(exp) and exp > 0 do
    from(u in User, where: u.id == ^id, update: [inc: [exp: ^exp]], select: u)
    |> Repo.update_all([])
  end

  @doc """
  Updates a user's password.
  """
  @spec update_password(User.t(), map) :: {:ok, User.t()} | changeset_error
  def update_password(%User{} = user, attrs) do
    Sessions.delete_user_sessions(user)

    user
    |> User.update_password_changeset(attrs)
    |> Repo.update()
  end

  def create_vk_user(%User{} = user, attrs) do
    event_cards =
      EventCard
      |> Repo.all()
      |> UserEventCard.cast_from_parent()
    user
    |> User.vk_changeset(attrs)
    |> put_assoc(:user_monopoly_event_cards, event_cards)
    |> Repo.insert!()
  end

  def get_vk_user(vk_id) do
    Repo.get_by(User, vk_id: vk_id)
  end

  def get_or_create_vk_user(vk_id, attrs) do
    case get_vk_user(vk_id) do
      nil -> create_vk_user(%User{}, attrs)
      %User{} = user -> user
    end
    |> User.get_public_fields()
  end
end
