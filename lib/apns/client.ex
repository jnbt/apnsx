defmodule APNSx.Client do
  @moduledoc """
    Instrumenable API to send notifications over APNS

    ## Example

        iex> {:ok, client} = APNSx.Client.start(host, port, options)
        iex> notification = %APNSx.Notification{
        ...>   id: 1_001,
        ...>   device_token: "..."
        ...>   payload: ~S({"aps": {"badge": 1}})
        ...> }
        iex> APNSx.Client.push(client, notification)
  """
  require Logger
  alias APNSx.Connection
  alias APNSx.Encoder
  alias APNSx.Notification

  @doc """
    Prepare a APNS connection to push notifications to `host`:`port` using
    the defined `options`
  """
  @spec start(String.t, non_neg_integer, Keyword.t) :: {:ok, pid}
  def start(host, port, options) do
    Task.start_link(fn -> connect(host, port, options) end)
  end

  @doc """
    Pushes a `notification` using the already started `client`
  """
  @spec push(pid, Notification.t) :: {:ok, pid} | {:error, any}
  def push(client, %Notification{} = notification) do
    case Notification.valid?(notification) do
      :ok ->
        send(client, {:push, notification})
        {:ok, client}
      error -> error
    end
  end

  defp connect(host, port, options) do
    {:ok, connection} = Connection.start(host, port, options)
    loop_connection(connection)
  end

  defp loop_connection(connection) do
    receive do
      {:push, message} ->
        Connection.write(connection, Encoder.to_binary(message))
        loop_connection(connection)
      {:recv, data} ->
        Logger.warn("APNS failure: #{inspect(data)}")
      :error ->
        Logger.error("Connection error")
      :closed ->
        Logger.debug("Connection closed")
    end
  end
end
