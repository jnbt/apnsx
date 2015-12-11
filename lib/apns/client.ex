defmodule APNSx.Client do
  require Logger
  alias APNSx.Connection
  alias APNSx.Encoder
  alias APNSx.Notification

  def start(host, port, options) do
    Task.start_link(fn -> connect(host, port, options) end)
  end

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
