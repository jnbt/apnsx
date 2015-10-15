defmodule APNSx.Decoder do
  alias APNSx.Failure
  alias APNSx.Feedback

  @moduledoc """
  Decodes APNS server responses into structs

  ## Specifications
  * [The Binary Interface and Notification Format](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4)
  """

  @doc """
  Returns the decoded `data` binary into a `%Failure` struct
  """
  @spec to_failure(binary) :: Failure.t
  def to_failure(<<8, code, id :: size(32)>> = data) do
    Failure.build(code, id)
  end

  @doc """
  Returns the decoded `data`into a `%Feedback` struct
  """
  @spec to_feedback(binary) :: Feedback.t
  def to_feedback(<<timestamp :: size(32), _ :: size(16), token :: binary-size(32)>> = data) do
    %Feedback{timestamp: timestamp, device_token: Base.encode16(token)}
  end
end
