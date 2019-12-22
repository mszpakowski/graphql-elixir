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

  alias PlateSlate.Menu
  alias PlateSlateWeb.Resolvers
  alias PlateSlateWeb.Schema.Middleware

  import_types(PlateSlateWeb.Schema.MenuTypes)
  import_types(PlateSlateWeb.Schema.OrderingTypes)
  import_types(PlateSlateWeb.Schema.AccountsTypes)

  def middleware(middleware, field, object) do
    middleware
    |> apply(:errors, field, object)
    |> apply(:get_string, field, object)
    |> apply(:debug, field, object)
  end

  defp apply(middleware, :errors, _field, %{identifier: :mutation}) do
    middleware ++ [Middleware.ChangesetErrors]
  end

  defp apply([], :get_string, field, %{identifier: :allergy_info}) do
    [{Abisnthe.Middleware.MapGet, to_string(field.identifier)}]
  end

  defp apply(middleware, :debug, _field, _object) do
    if System.get_env("DEBUG") do
      [{Middleware.Debug, :start}] ++ middleware
    else
      middleware
    end
  end

  defp apply(middleware, _, _, _) do
    middleware
  end

  def dataloader() do
    Dataloader.new()
    |> Dataloader.add_source(Menu, Menu.data())
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader())
  end

  def plugins() do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  query do
    field :me, :user do
      middleware(Middleware.Authorize, :any)
      resolve(&Resolvers.Accounts.me/3)
    end

    @desc "The list of available items on the menu"
    import_fields(:menu_queries)
  end

  mutation do
    field :create_menu_item, :menu_item_result do
      arg(:input, non_null(:menu_item_input))

      middleware(Middleware.Authorize, "employee")
      resolve(&Resolvers.Menu.create_item/3)
    end

    field :place_order, :order_result do
      arg(:input, non_null(:place_order_input))

      middleware(Middleware.Authorize, :any)
      resolve(&Resolvers.Ordering.place_order/3)
    end

    field :ready_order, :order_result do
      arg(:id, non_null(:id))

      middleware(Middleware.Authorize, "employee")
      resolve(&Resolvers.Ordering.ready_order/3)
    end

    field :complete_order, :order_result do
      arg(:id, non_null(:id))

      middleware(Middleware.Authorize, "employee")
      resolve(&Resolvers.Ordering.complete_order/3)
    end

    field :login, :session do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      arg(:role, non_null(:role))

      resolve(&Resolvers.Accounts.login/3)

      middleware(fn resolution, _ ->
        with %{value: %{user: user}} <- resolution do
          %{resolution | context: Map.put(resolution.context, :current_user, user)}
        end
      end)
    end
  end

  subscription do
    field :new_order, :order do
      config(fn _args, %{context: context} ->
        case context[:current_user] do
          %{role: "customer", id: id} ->
            {:ok, topic: id}

          %{role: "employee"} ->
            {:ok, topic: "*"}

          _ ->
            {:error, "unauthorized"}
        end
      end)

      trigger(:place_order,
        topic: fn
          %{order: order} -> [order.customer_id, "*"]
          _ -> []
        end
      )

      resolve(fn %{order: order}, _, _ -> {:ok, order} end)
    end

    field :update_order, :order do
      arg(:id, non_null(:id))

      config(fn args, %{context: context} ->
        case context[:current_user] do
          %{role: role} when role in ["customer", "employee"] ->
            {:ok, topic: args.id}

          _ ->
            {:error, "unauthorized"}
        end
      end)

      trigger([:ready_order, :complete_order],
        topic: fn
          %{order: order} -> [order.id]
          _ -> []
        end
      )

      resolve(fn %{order: order}, _, _ -> {:ok, order} end)
    end
  end

  @desc "An error ecountered trying to persist input"
  object :input_error do
    field(:key, non_null(:string))
    field(:message, non_null(:string))
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end

  scalar :date do
    parse(fn input ->
      with %Absinthe.Blueprint.Input.String{value: value} <- input,
           {:ok, date} <- Date.from_iso8601(value) do
        {:ok, date}
      else
        _ -> :error
      end
    end)

    serialize(fn date ->
      Date.to_iso8601(date)
    end)
  end

  scalar :decimal do
    parse(fn
      %{value: value}, _ ->
        Decimal.parse(value)

      _, _ ->
        :error
    end)

    serialize(&to_string/1)
  end
end
