defmodule APNSx.NotificationTest do
  use ExUnit.Case, async: true
  alias APNSx.Notification

  test "holds default values" do
    notification = %Notification{}
    assert nil == notification.device_token
    assert nil == notification.payload
    assert nil == notification.id
    assert 86_400_000 == notification.expiry
    assert 5 == notification.priority
  end
end
