defmodule CrocWeb.ExAdmin.Repo.Games.Monopoly.Card do
  use ExAdmin.Register
  alias Croc.Repo.Games.Monopoly.Card

  register_resource Croc.Repo.Games.Monopoly.Card do
    update_changeset :changeset_update
    create_changeset :changeset_update

    index do

      selectable_column

      column :image_url, fn x ->
        Phoenix.HTML.Tag.img_tag(x.image_url, [style: "width: 40px;"])
      end

      column :id
      column :name
      column :type
      column :monopoly_type
      column :rarity
      column :disabled
      column :is_default

      actions
    end

    show card do
      attributes_table "Картинка" do
        row :image_url, [image: true, height: 100], fn x ->
          x.image_url
        end
      end

      attributes_table

    end
  end
end
