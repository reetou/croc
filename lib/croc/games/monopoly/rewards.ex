defmodule Croc.Games.Monopoly.Rewards do
  alias Croc.{
    Accounts,
    Accounts.User
  }
  alias Croc.Repo.Games.Monopoly.Card
  alias Croc.Repo
  import Ecto.Query

  def get_random_card() do
    from(c in Card, where: c.is_default != true, select: %{ id: c.id, position: c.position })
    |> first()
    |> Repo.one()
  end
end
