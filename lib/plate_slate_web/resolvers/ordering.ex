defmodule PlateSlateWeb.Resolvers.Ordering do
  import Absinthe.Resolution.Helpers

  alias PlateSlate.Ordering

  def place_order(_, %{input: place_order_input}, %{context: context}) do
    with place_order_input <- maybe_put_user_id(place_order_input, context),
         {:ok, order} <- Ordering.create_order(place_order_input) do
      {:ok, %{order: order}}
    end
  end

  def ready_order(_, %{id: id}, _) do
    order = Ordering.get_order!(id)

    with {:ok, order} <- Ordering.update_order(order, %{state: "ready"}) do
      {:ok, %{order: order}}
    end
  end

  def complete_order(_, %{id: id}, _) do
    order = Ordering.get_order!(id)

    with {:ok, order} <- Ordering.update_order(order, %{state: "complete"}) do
      {:ok, %{order: order}}
    end
  end

  def order_history(item, args, _) do
    one_month_ago = Date.add(Date.utc_today(), -30)

    args =
      Map.update(args, :since, one_month_ago, fn date ->
        date || one_month_ago
      end)

    {:ok, %{item: item, args: args}}
  end

  def orders(%{item: item, args: args}, _, _) do
    batch({Ordering, :orders_by_item_name, args}, item.name, fn orders ->
      {:ok, Map.get(orders, item.name, [])}
    end)
  end

  def stat(stat) do
    fn %{item: item, args: args}, _, _ ->
      batch({Ordering, :orders_stats_by_name, args}, item.name, fn results ->
        {:ok, results[item.name][stat] || 0}
      end)
    end
  end

  defp maybe_put_user_id(place_order_input, %{current_user: %{role: "customer", id: id}}),
    do: Map.put(place_order_input, :customer_id, id)

  defp maybe_put_user_id(place_order_input, _), do: place_order_input
end
