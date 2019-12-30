defmodule Croc.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias Croc.Repo
  alias Croc.Sessions.Session

  @type t :: %__MODULE__{
          id: integer,
          username: String.t(),
          email: String.t(),
          password_hash: String.t(),
          confirmed_at: DateTime.t() | nil,
          reset_sent_at: DateTime.t() | nil,
          sessions: [Session.t()] | %Ecto.Association.NotLoaded{},
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "users" do
    field :username, :string
    field :first_name, :string
    field :last_name, :string
    field :vk_id, :integer
    field :image_url, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :confirmed_at, :utc_datetime
    field :reset_sent_at, :utc_datetime
    field :is_admin, :boolean
    field :banned, :boolean
    has_many :sessions, Session, on_delete: :delete_all

    has_many :user_monopoly_cards, Croc.Repo.Games.Monopoly.UserCard

    has_many :monopoly_cards, through: [:user_monopoly_cards, :monopoly_card]

    timestamps()
  end

  def find_user(id) do
    __MODULE__
    |> Repo.get(id)
  end

  def vk_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:first_name, :vk_id, :last_name, :image_url])
    |> validate_required([:vk_id])
    |> unique_constraint(:vk_id)
  end

  def changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> unique_email
  end

  def create_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:email, :password, :username])
    |> validate_required([:email, :password, :username])
    |> unique_email
    |> validate_password(:password)
    |> put_pass_hash
  end

  def confirm_changeset(%__MODULE__{} = user, confirmed_at) do
    change(user, %{confirmed_at: confirmed_at})
  end

  def password_reset_changeset(%__MODULE__{} = user, reset_sent_at) do
    change(user, %{reset_sent_at: reset_sent_at})
  end

  def update_password_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password(:password)
    |> put_pass_hash()
    |> change(%{reset_sent_at: nil})
  end

  defp unique_email(changeset) do
    changeset
    |> validate_format(
      :email,
      ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9-\.]+\.[a-zA-Z]{2,}$/
    )
    |> validate_length(:email, max: 255)
    |> unique_constraint(:email)
  end

  # In the function below, strong_password? just checks that the password
  # is at least 8 characters long.
  # See the documentation for NotQwerty123.PasswordStrength.strong_password?
  # for a more comprehensive password strength checker.
  defp validate_password(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, password ->
      case strong_password?(password) do
        {:ok, _} -> []
        {:error, msg} -> [{field, options[:message] || msg}]
      end
    end)
  end

  # If you are using Bcrypt or Pbkdf2, change Argon2 to Bcrypt or Pbkdf2
  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Argon2.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset

  defp strong_password?(password) when byte_size(password) > 7 do
    {:ok, password}
  end

  defp strong_password?(_), do: {:error, "The password is too short"}

  def get_public_fields(%__MODULE__{} = user) do
    assoc = Repo.all(Ecto.assoc(user, :monopoly_cards))
    user = Map.put(user, :user_monopoly_cards, assoc)
    %{}
    |> Map.put(:email, user.email)
    |> Map.put(:id, user.id)
    |> Map.put(:username, user.username)
    |> Map.put(:first_name, user.first_name)
    |> Map.put(:image_url, user.image_url)
    |> Map.put(:last_name, user.last_name)
    |> Map.put(:user_monopoly_cards, user.user_monopoly_cards)
  end
end
