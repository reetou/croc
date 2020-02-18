# Croc [![CircleCI](https://circleci.com/gh/reetou/croc/tree/master.svg?style=svg&circle-token=b1764001723e2679daea66cbc5f5eb549b418122)](https://circleci.com/gh/reetou/croc/tree/master)

## UI alpha version
![pic](https://i.imgur.com/WdaCBhI.png)
![pic](https://i.imgur.com/ZTz8jVx.png)

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`
  
  This is an api backend for Monopoly game, which could be released on VK Mini Apps platform but it did not happen. I thought it could be useful to use this project as a demo to demonstrate my Elixir experience and progress through time.
  
  Player can create lobby and invite other people to join him or he can join someone's lobby. Lobby is a GenServer and keeps track of people in current lobby, their inventory and stuff. Lobby creator can call server to start game, which will kill lobby process and start processes for game and chat
  
  Each monopoly game instance is a GenServer which receives events from players and broadcasting it via Phoenix Channels.
  
  Each game instance has a chat, which is also a GenServer and stores messages from all users sending messages to all users, personal messages and messages from game itself (marked with type event)
  
  Player interacts with backend via API first to check if he is already in DB, otherwise add his VK ID and keep track of his game progress (exp, games won, games played).
  
  Frontend is only available on /vk route with VK UI mobile interface. / route will show interface for local development or debug :)
  
  There is an admin pages to edit `cards` or `event_cards` but I didn't have enough time to finish it.
  
  React is used for frontend.
  
  All secrets are now not valid

  Tests are in `test` directory, there are currently 151 tests for backend logic.
