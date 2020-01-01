defmodule PlateSlateWeb.ItemController do
  use PlateSlateWeb, :controller
  use Absinthe.Phoenix.Controller, schema: PlateSlateWeb.Schema, action: [mode: :internal]

  @graphql """
  query {
    menuItems @put {
      category
      order_history {
        quantity
      }
    }
  }
  """
  def index(conn, result) do
    IO.inspect(result)
    render(conn, "index.html", items: result.data.menuItems)
  end

  @graphql """
  query ($id: ID!, $since: Date) {
    menu_item(id: $id) @put {
      order_history(since: $since) {
        quantity
        gross
        orders
      }
    }
  }
  """
  def show(conn, %{data: %{menu_item: nil}}) do
    conn
    |> put_flash(:info, "Menu item not found")
    |> redirect(to: "/admin/items")
  end

  def show(conn, %{data: %{menu_item: item}}) do
    since = variables(conn)["since"] || "2018-01-01"
    render(conn, "show.html", item: item, since: since)
  end
end
