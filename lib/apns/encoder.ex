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

      iex> APNSx.Encoder.to_binary(%APNSx.Notification{
      ...>   device_token: "...",
      ...>   payload: ~S({"aps": {"badge": 1}})
      ...> })
      <<2, 0, 0, 0, 7, 0>>
  """
  @spec to_binary(Notification.t) :: binary
  def to_binary(%Notification{} = notification) do
    notification
    |> frame
    |> package
  end

  defp frame(notification) do
    token   = encode_device_token(notification.device_token)
    payload = notification.payload
    <<
      1                     :: 8,
      32                    :: 16,
      token                 :: binary,
      2                     :: 8,
      byte_size(payload)    :: 16,
      payload               :: binary,
      3                     :: 8,
      4                     :: 16,
      notification.id       :: 32,
      4                     :: 8,
      4                     :: 16,
      notification.expiry   :: 32,
      5                     :: 8,
      1                     :: 16,
      notification.priority :: 8
    >>
  end

  defp package(frame) do
    <<
      2                ::  8,
      byte_size(frame) ::  32,
      frame            ::  binary
    >>
  end

  defp encode_device_token(token) do
    token
    |> String.replace(~r/[<\s>]/, "")
    |> Base.decode16!(case: :mixed)
  end
end
