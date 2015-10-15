defmodule APNSx.Encoder do
  alias APNSx.Notification

  @moduledoc """
  Encoding of arbitrary notifications into the APNS binary format

  ## Specifications
  * [The Binary Interface and Notification Format](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4)
  """

  @doc """
  Returns the binary representation of the `notification`

  ## Example
    iex> APNSx.Encoder.to_binary(%APNSx.Notification{device_token: "ce8be627", payload: ~S({"aps": {"badge": 1}})})
    <<2, 0, 0, 0, 7, ...>>
  """
  @spec to_binary(Notification.t) :: binary
  def to_binary(%Notification{} = notification) do
    Map.from_struct(notification)
    |> itemize
    |> frame
  end

  defp frame(data) do
    data_size = byte_size(data)
    <<2>> <> <<data_size :: size(32)>> <> data
  end

  defp itemize(n, acc \\ <<>>)

  defp itemize(%{device_token: token} = n, acc) do
    normalized = normalize_device_token(token)
    32 = byte_size(normalized)
    encoded = <<1>> <> <<32 :: size(16)>> <> normalized
    itemize(Dict.delete(n, :device_token), acc <> encoded)
  end

  defp itemize(%{payload: payload} = n, acc) do
    payload_size = byte_size(payload)
    encoded = <<2>> <> <<payload_size :: size(16)>> <> payload
    itemize(Dict.delete(n, :payload), acc <> encoded)
  end

  defp itemize(%{id: id} = n, acc) do
    encoded = <<3>> <> <<4 :: size(16)>> <> <<id :: size(32)>>
    itemize(Dict.delete(n, :id), acc <> encoded)
  end

  defp itemize(%{expiry: expiry} = n, acc) do
    encoded = <<4>> <> <<4 :: size(16)>> <> <<expiry :: size(32)>>
    itemize(Dict.delete(n, :expiry), acc <> encoded)
  end

  defp itemize(%{priority: priority} = n, acc) do
    encoded = <<5>> <> <<1 :: size(16)>> <> <<priority :: size(8)>>
    itemize(Dict.delete(n, :priority), acc <> encoded)
  end

  defp itemize(_, acc), do: acc

  defp normalize_device_token(token) do
    token
    |> String.replace(~r/[<\s>]/, "")
    |> String.upcase
    |> Base.decode16!
  end
end
