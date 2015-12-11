defmodule APNSx.NotificationTest do
  use ExUnit.Case, async: true
  doctest APNSx.Notification
  alias APNSx.Notification

  setup do
    notification = %Notification{
      device_token: "ce8be627 2e43e855 16033e24 b4c28922 0eeda487 9c477160 b2545e95 b68b5969",
      payload: ~S({"aps": {"badge": 1}}),
      id: 1,
    }
    {:ok, notification: notification}
  end

  test "holds default values" do
    notification = %Notification{}
    assert nil == notification.device_token
    assert nil == notification.payload
    assert nil == notification.id
    assert 86_400_000 == notification.expiry
    assert 5 == notification.priority
  end

  test "valid? ensures id presence", %{notification: notification} do
    result = Notification.valid?(%{notification | id: nil})
    assert {:error, {:id, :must_be_present}} == result
  end

  test "valid? ensures id to be integer", %{notification: notification} do
    result = Notification.valid?(%{notification | id: "wrong"})
    assert {:error, {:id, :must_be_integer}} == result
  end

  test "valid? ensures payload presence", %{notification: notification} do
    result = Notification.valid?(%{notification | payload: nil})
    assert {:error, {:payload, :must_be_present}} == result
  end

  test "valid? ensures device_token presence", %{notification: notification} do
    result = Notification.valid?(%{notification | device_token: nil})
    assert {:error, {:device_token, :must_be_present}} == result
  end

  test "valid? ensures payload size", %{notification: notification} do
    large_payload = String.duplicate("a", 2_049)
    result = Notification.valid?(%{notification | payload: large_payload})
    assert {:error, {:payload, :exceeds_max_size, 2_048}} == result

    limit_payload = String.duplicate("a", 2_048)
    assert :ok == Notification.valid?(%{notification | payload: limit_payload})
  end

  test "valid? ensures valid priority", %{notification: notification} do
    result = Notification.valid?(%{notification | priority: 99})
    assert {:error, {:priority, :is_invalid}} == result
  end
end
