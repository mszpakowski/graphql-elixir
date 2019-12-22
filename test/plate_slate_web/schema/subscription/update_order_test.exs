defmodule PlateSlateWeb.Schema.Subscription.UpdateOrderTest do
  use PlateSlateWeb.SubscriptionCase

  @subscription """
  subscription ($id: ID!) {
    updateOrder(id: $id) { state }
  }
  """
  @mutation """
  mutation ($id: ID!) {
    readyOrder(id: $id) { errors { message } }
  }
  """
  @login """
  mutation ($email: String!, $role: Role!) {
    login(role: $role, email: $email, password: "super-secret") {
      token
    }
  }
  """
  test "subscribe to order update", %{socket: socket} do
    # login
    user = Factory.create_user("employee")
    ref = push_doc(socket, @login, variables: %{"email" => user.email, role: "EMPLOYEE"})
    assert_reply(ref, :ok, %{data: %{"login" => %{"token" => _}}}, 1_000)

    reuben = menu_item("Reuben")

    {:ok, order1} =
      PlateSlate.Ordering.create_order(%{
        customer_number: 123,
        items: [%{menu_item_id: reuben.id, quantity: 2}]
      })

    {:ok, order2} =
      PlateSlate.Ordering.create_order(%{
        customer_number: 124,
        items: [%{menu_item_id: reuben.id, quantity: 1}]
      })

    ref = push_doc(socket, @subscription, variables: %{"id" => order1.id})
    assert_reply(ref, :ok, %{subscriptionId: _subscription_ref1})

    ref = push_doc(socket, @subscription, variables: %{"id" => order2.id})
    assert_reply(ref, :ok, %{subscriptionId: subscription_ref2})

    ref = push_doc(socket, @mutation, variables: %{"id" => order2.id})
    assert_reply(ref, :ok, reply)

    refute reply[:errors]
    refute reply[:data]["readyOrder"]["errors"]

    assert_push("subscription:data", push)

    expected = %{
      result: %{data: %{"updateOrder" => %{"state" => "ready"}}},
      subscriptionId: subscription_ref2
    }

    assert expected == push
  end
end
