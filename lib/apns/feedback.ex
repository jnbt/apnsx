defmodule APNSx.Feedback do
  @moduledoc """
  Describes a feedback information from the APNS server
  """

  @type t :: %__MODULE__{
    timestamp: non_neg_integer,
    device_token: String.t}

  defstruct [
    timestamp: nil,
    device_token: nil]
end
