defmodule CrocWeb.ExAdmin.Dashboard do
  use ExAdmin.Register
  import ExAdmin.Utils
  alias Croc.Games.Monopoly.Lobby
  alias Croc.Games.Monopoly
  alias Croc.Helpers

  def user_path(id) do
    "/exadmin/users/#{id}"
  end

  def players_in_games() do
    Monopoly.get_all()
    |> Enum.flat_map(fn g -> g.players end)
    |> length()
  end

  def games_in_total() do
    Monopoly.get_all()
    |> length()
  end

  def players_in_lobbies() do
    Lobby.get_all()
    |> Enum.flat_map(fn l -> l.players end)
    |> length()
  end

  def lobbies_in_total() do
    Lobby.get_all()
    |> length()
  end

  register_page "Dashboard" do
    menu priority: 1, label: "Dashboard"
    content do

      panel "General info" do
        markup_contents do
          h3 "Сейчас играет: #{players_in_games()} игроков"
          h3 "Игроков в лобби: #{players_in_lobbies()}"

          h3 "Всего игр: #{games_in_total()}"
          h3 "Всего лобби: #{lobbies_in_total()}"

        end
      end

      columns do
        column do
          panel "Lobbies" do
            Lobby.get_all()
            |> table_for do
                 column "Lobby ID", fn(o) -> text o.lobby_id end
                 column "Chat ID", fn o -> text o.chat_id end
                 column "Duration", fn o -> text Helpers.duration(o.created_at) end
                 column "Players", fn(o) ->
                   ul do
                     Enum.map(o.players, fn p ->
                       li do
                         a p.player_id, href: user_path(p.player_id)
                       end
                     end)
                   end
                 end
               end
          end

          panel "Games" do
            Monopoly.get_all()
            |> table_for do
                 column "Game ID", fn(g) -> text g.game_id end
                 column "Chat ID", fn g -> text g.chat_id end
                 column "Round", fn g -> text g.round end
                 column "Duration", fn g -> text Helpers.duration(g.started_at) end
                 column "Players", fn(g) ->
                   ul do
                     Enum.map(g.players, fn p ->
                       li do
                         a p.player_id, href: user_path(p.player_id)
                       end
                     end)
                   end
                 end
               end
          end
        end
      end
    end
  end
end
