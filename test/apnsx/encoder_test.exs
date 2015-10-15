defmodule APNSx.EncoderTest do
  use ExUnit.Case
  alias APNSx.Encoder
  alias APNSx.Notification

  @notification %Notification{
    device_token: "<ce8be627 2e43e855 16033e24 b4c28922 0eeda487 9c477160 b2545e95 b68b5969>",
    payload: ~S({"aps": {"badge": 1}}),
    id: 42,
    expiry: 1444909802,
    priority: 5
  }

  @encoded Encoder.to_binary(@notification)

  test "has command 2" do
    <<2, _ :: binary>> = @encoded
  end

  test "uses correct frame size" do
    <<_, length :: size(32), frame :: binary>> = @encoded
    assert byte_size(frame) == length
  end

  test "frame holds 5 items" do
    items = extract_items
    assert 5 == length(items)
  end

  test "first item is device token" do
    {1, 32, token} = Enum.at(extract_items, 0)
    assert 32 == byte_size(token)
    assert "CE8BE6272E43E85516033E24B4C289220EEDA4879C477160B2545E95B68B5969"
           == Base.encode16(token)
  end

  test "second item is payload" do
    {2, 21, payload} = Enum.at(extract_items, 1)
    assert 21 == byte_size(payload)
    assert ~S({"aps": {"badge": 1}}) == payload
  end

  test "third item is id" do
    {3, 4, <<id::size(32)>>} = Enum.at(extract_items, 2)
    assert 42 == id
  end

  test "forth item is expiry" do
    {4, 4, <<expiry::size(32)>>} = Enum.at(extract_items, 3)
    assert 1444909802 == expiry
  end

  test "fifth item is priority" do
    {5, 1, <<priority>>} = Enum.at(extract_items, 4)
    assert 5 == priority
  end

  test "handles empty notification" do
    assert <<2, 0, 0, 0, 0>> == Encoder.to_binary(%Notification{})
  end

  defp extract_items(data \\ @encoded) do
    <<_ :: size(40), frames :: binary>> = data
    extract_items(frames, [])
  end
  defp extract_items(<<>>, acc), do: acc
  defp extract_items(<<id, length :: size(16), content :: binary-size(length), rest :: binary>>, acc) do
    extract_items(rest, acc ++ [{id, length, content}])
  end
end
