defmodule Croc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Croc.Repo,
      # Start the endpoint when the application starts
      CrocWeb.Endpoint,
      # Starts a worker by calling: Croc.Worker.start_link(arg)
      # {Croc.Worker, arg},
      Croc.Games.Lobby.Supervisor,
      {Registry, [keys: :unique, name: :monopoly_registry]},
      {Registry, [keys: :unique, name: :lobby_registry]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Croc.Supervisor]
    Memento.Table.create!(Croc.Games.Monopoly.Lobby.Player)
    Memento.Table.create!(Croc.Games.Monopoly.Player)
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CrocWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
