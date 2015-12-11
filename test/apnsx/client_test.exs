defmodule APNSx.ClientTest do
  use ExUnit.Case, async: true
  alias APNSx.Client
  alias APNSx.Notification

  test "checks notification" do
    client = nil
    result = Client.push(client, %Notification{})
    assert {:error, {:id, :must_be_present}} == result
  end
end
