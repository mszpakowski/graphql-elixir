defmodule PlateSlateWeb.Resolvers.Ordering do
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

  defp maybe_put_user_id(place_order_input, %{current_user: %{role: "customer", id: id}}),
    do: Map.put(place_order_input, :customer_id, id)

  defp maybe_put_user_id(place_order_input, _), do: place_order_input
end
