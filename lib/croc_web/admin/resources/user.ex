defmodule CrocWeb.ExAdmin.Accounts.User do
  use ExAdmin.Register
  alias Croc.Repo

  register_resource Croc.Accounts.User do
    update_changeset :changeset_update
    create_changeset :changeset_create


    show user do

      attributes_table do
        row :image_url, [image: true, height: 100], fn x ->
          x.image_url
        end
        row :first_name
        row :last_name
        row :vk_id
        row :email
        row :is_admin, fn x -> if x.is_admin == true, do: "Админ", else: "Пользователь" end
        row :banned, fn x -> if x.banned == true, do: "Забанен", else: "Нет" end
        row :confirmed_at
        row :reset_sent_at
      end
      # create a panel to list the question's choices
      panel "Карточки" do
        table_for(Repo.preload(user, :monopoly_cards).monopoly_cards) do
          column :id
          column :name
          column :type
          column :image_url
        end
      end

      # create a panel to list the question's choices
      panel "Карты события" do
        table_for(Repo.preload(user, :monopoly_event_cards).monopoly_event_cards) do
          column :id
          column :name
          column :type
          column :image_url, fn x ->
            Phoenix.HTML.Tag.img_tag(x.image_url, [style: "width: 80px;"])
          end
        end
      end
    end
  end
end
