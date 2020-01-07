defmodule CrocWeb.ExAdmin.ChatBroadcaster do
  use ExAdmin.Register
  import ExAdmin.Utils
  alias Croc.Games.Monopoly.Lobby
  alias Croc.Games.Monopoly
  alias Croc.Helpers
  alias Croc.Games.Chat.Admin.Monopoly.Broadcaster

  @users_path "/exadmin/users"

  register_page "Chat_broadcaster" do
    menu priority: 2, label: "Chat broadcaster"
    content do
      panel "Чат" do

        markup_contents do

          div do

            Phoenix.View.render(CrocWeb.AdminView, "game_messages.html", [topic: Broadcaster.all_game_messages_topic(), users_path: @users_path])
            |> Phoenix.HTML.safe_to_string()
            |> IO.inspect(label: "Will render")
          end

        end
      end
    end
  end
end
