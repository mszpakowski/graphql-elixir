defmodule PlateSlateWeb.Schema.Mutation.CreateMenuTest do
  use PlateSlateWeb.ConnCase, async: true

  import Ecto.Query

  alias PlateSlate.{Repo, Menu}

  setup do
    PlateSlate.Seeds.run()

    category_id =
      from(t in Menu.Category, where: t.name == "Sandwiches")
      |> Repo.one!()
      |> Map.fetch!(:id)
      |> to_string()

    {:ok, category_id: category_id}
  end

  @query """
  mutation ($menuItem: MenuItemInput!) {
    createMenuItem(input: $menuItem) {
      errors { key message }
      menuItem {
        name
        description
        price
      }
    }
  }
  """
  test "createMenuItem field creates an item", %{category_id: category_id} do
    menu_item = %{
      name: "French Dip",
      description: "Roast beef, carmelized onions, horseradish, ...",
      price: "5.75",
      category_id: category_id
    }

    conn = post(build_conn(), "/api", query: @query, variables: %{menuItem: menu_item})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createMenuItem" => %{
                 "errors" => nil,
                 "menuItem" => %{
                   "name" => menu_item[:name],
                   "description" => menu_item[:description],
                   "price" => menu_item[:price]
                 }
               }
             }
           }
  end

  test "creating a menu item with existing name fails", %{category_id: category_id} do
    menu_item = %{
      name: "Reuben",
      description: "Roast beef, carmelized onions, horseradish, ...",
      price: "5.75",
      category_id: category_id
    }

    conn = post(build_conn(), "/api", query: @query, variables: %{menuItem: menu_item})

    assert json_response(conn, 200) == %{
             "data" => %{
               "createMenuItem" => %{
                 "errors" => [
                   %{"key" => "name", "message" => "has already been taken"}
                 ],
                 "menuItem" => nil
               }
             }
           }
  end
end
