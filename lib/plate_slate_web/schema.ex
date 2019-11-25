# ---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
# ---
defmodule PlateSlateWeb.Schema do
  use Absinthe.Schema

  alias PlateSlateWeb.Resolvers

  query do
    @desc "The list of available items on the menu"
    field(:menu_items, list_of(:menu_item)) do
      arg(:matching, :string)

      resolve(&Resolvers.Menu.menu_items/3)
    end
  end

  @desc "Available item on the menu"
  object :menu_item do
    @desc "Unique identifier"
    field(:id, :id)
    @desc "Name of the item"
    field(:name, :string)
    @desc "Description of the item"
    field(:description, :string)
    @desc "Price of the item"
    field(:price, :float)
  end
end
