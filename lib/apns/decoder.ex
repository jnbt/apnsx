defmodule APNSx.Decoder do
  alias APNSx.Failure
  alias APNSx.Feedback

  @moduledoc """
  Decodes APNS server responses into structs

  ## Specifications
  * [The Binary Interface and Notification Format](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4)
  """

  @doc """
  Returns the decoded `arg` binary as a `%Failure` struct

  ## Example

      iex> APNSx.Decoder.to_failure(<<8, 1, 1 :: 32>>)
      %APNSx.Failure{code: 1, reason: "Processing error", id: 1}
  """
  @spec to_failure(binary) :: Failure.t
  def to_failure(<<8, code, id :: size(32)>>) do
    Failure.build(code, id)
  end

  @doc """
  Returns the decoded `arg` binary as a `%Feedback` struct

  ## Example

      iex> APNSx.Decoder.to_feedback(<<1 :: 32, 32 :: 16, 1 :: 256>>)
      %APNSx.Feedback{
        timestamp: 1,
        device_token: "0000000000000000000000000000000000000000000000000000000000000001"
      }
  """
  @spec to_feedback(binary) :: Feedback.t
  def to_feedback(<<timestamp :: size(32), _ :: size(16), token :: binary-size(32)>>) do
    %Feedback{timestamp: timestamp, device_token: Base.encode16(token)}
  end
end
