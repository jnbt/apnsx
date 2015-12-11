defmodule APNSx.Failure do
  @moduledoc """
  Describes a error-response packet from the APNS server
  """

  @descriptions %{
    0 => "No errors encountered",
    1 => "Processing error",
    2 => "Missing device token",
    3 => "Missing topic",
    4 => "Missing payload",
    5 => "Invalid token size",
    6 => "Invalid topic size",
    7 => "Invalid payload size",
    8 => "Invalid token",
    256 => "None (unknown)"}

  @type t :: %__MODULE__{
    code: non_neg_integer,
    reason: String.t,
    id: non_neg_integer}

  defstruct [
    code: nil,
    reason: nil,
    id: nil]

  @doc """
  Returns a `%APNSx.Failure` struct for the given status `code` and the
  `id` if the failed notification

  ## Example
    iex> APNSx.Failure.build(1, 1_001)
    %APNSx.Failure{code: 1, reason: "Processing error", id: 1_001}
  """
  @spec build(non_neg_integer, non_neg_integer) :: t
  def build(code, id) do
    %__MODULE__{
      code: code,
      reason: Dict.get(@descriptions, code, @descriptions[256]),
      id: id}
  end
end

defimpl String.Chars, for: APNSx.Failure do
  def to_string(failure), do: failure.reason
end
