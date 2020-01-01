defmodule CrocWeb.ExAdmin.Repo.Games.Monopoly.EventCard do
  use ExAdmin.Register

  register_resource Croc.Repo.Games.Monopoly.EventCard do

    index do

      selectable_column

      column :image_url, fn x ->
        Phoenix.HTML.Tag.img_tag(x.image_url, [style: "width: 40px;"])
      end

      column :id
      column :name, fn x ->
        a truncate(x.name), href: admin_resource_path(x, :show)
      end
      column :type
      column :rarity
      column :disabled

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
