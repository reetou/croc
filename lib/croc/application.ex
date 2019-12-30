defmodule Croc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    # List all child processes to be supervised
    prod_children =
      case Mix.env() do
        :prod -> [{Cluster.Supervisor, [Application.get_env(:libcluster, :topologies), [name: Croc.ClusterSupervisor]]}]
        :dev -> [{Cluster.Supervisor, [Application.get_env(:libcluster, :topologies, []), [name: Croc.ClusterSupervisor]]}]
        _ -> []
      end
    Logger.info("Production children length: #{length prod_children}")
    children = [
      # Start the Ecto repository
      Croc.Repo,
      # Start the endpoint when the application starts
      CrocWeb.Endpoint,
      # Starts a worker by calling: Croc.Worker.start_link(arg)
      # {Croc.Worker, arg},
      Croc.Games.Chat.Admin.MessageProducer,
      Croc.Games.Chat.Admin.Monopoly.Broadcaster,
      Croc.Games.Lobby.Supervisor,
      Croc.Games.Monopoly.Supervisor,
      Croc.Games.Chat.Supervisor,
      {Registry, [keys: :unique, name: :monopoly_registry]},
      {Registry, [keys: :unique, name: :lobby_registry]},
      {Registry, [keys: :unique, name: :chat_registry]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Croc.Supervisor]
    Memento.Table.create!(Croc.Games.Monopoly.Lobby.Player)
    Memento.Table.create!(Croc.Games.Monopoly.Player)
    Supervisor.start_link(prod_children ++ children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CrocWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
