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
    expiry: 86_400_000,
    priority: 5]

  @doc """
  The maximal payload is 2 kilobytes
  """
  @maximum_payload_size 2_048 # bytes

  @doc """
  Checks a `notification` to be valid for transmission

  ## Example

      iex> APNSx.Notification.valid?(%APNSx.Notification{})
      {:error, {:id, :must_be_present}}
  """
  def valid?(%__MODULE__{} = notification) do
    check(notification)
  end

  defp check(%__MODULE__{id: nil}),
    do: {:error, {:id, :must_be_present}}
  defp check(%__MODULE__{id: id})
    when not is_integer(id),
    do: {:error, {:id, :must_be_integer}}
  defp check(%__MODULE__{payload: nil}),
    do: {:error, {:payload, :must_be_present}}
  defp check(%__MODULE__{payload: payload})
    when byte_size(payload) > @maximum_payload_size,
    do: {:error, {:payload, :exceeds_max_size, @maximum_payload_size}}
  defp check(%__MODULE__{device_token: nil}),
    do: {:error, {:device_token, :must_be_present}}
  defp check(%__MODULE__{priority: priority})
    when not priority in [5, 10],
    do: {:error, {:priority, :is_invalid}}
  defp check(_), do: :ok
end
