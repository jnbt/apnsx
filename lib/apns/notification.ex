defmodule APNSx.Notification do
  @moduledoc """
  Describes a push notification to be used with APNS
  """

  @type t :: %__MODULE__{
    device_token: String.t,
    payload: String.t,
    id: non_neg_integer,
    expiry: non_neg_integer,
    priority: non_neg_integer}

  defstruct [
    device_token: nil,
    payload: nil,
    id: nil,
    expiry: nil,
    priority: nil]
end
