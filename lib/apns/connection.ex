defmodule APNSx.Connection do
  use GenServer
  require Logger

  def start(host, port, options) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    :ok = GenServer.call(pid, {:connect, host, port, options})
    {:ok, pid}
  end

  def push(connection, message) do
    GenServer.call(connection, {:send, message})
  end

  def close(connection) do
    GenServer.call(connection, :close)
  end

  def handle_call({:connect, host, port, options}, _, _) do
    Logger.info("Connecting to: #{host}:#{port}")
    Logger.debug(inspect(options))

    :ssl.start()
    {:ok, socket} = ssl_connect(host, port, options)
    :ok = ssl_accept(socket)
    {:reply, :ok, socket}
  end

  def handle_call({:send, message}, _, socket) do
    Logger.debug("Sending: #{inspect(message)}")
    :ok = ssl_send(socket, message)
    {:reply, :ok, socket}
  end

  def handle_call(:close, socket) do
    Logger.debug("Closing connection")
    :ok = ssl_close(socket)
    {:reply, :ok, socket}
  end

  def handle_info({:ssl_closed, _}, socket) do
    Logger.info("Connection closed")
    {:stop, :normal, []}
  end

  def handle_info({:ssl, s, d}, socket) do
    Logger.debug("Received: #{inspect(s)}, #{inspect(d)}")
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    Logger.warn("Unknown info: #{inspect(msg)}")
    {:noreplay, socket}
  end

  defp ssl_send(socket, message) do
    :ssl.send(socket, message)
  end

  defp ssl_options(options) do
    opts = case Keyword.get(options, :sandbox) do
      # Force TLS v1.1 as a workaround for an OTP SSL bug
      # See
      # * https://github.com/inaka/apns4erl/pull/65
      # * http://erlang.org/pipermail/erlang-questions/2015-June/084935.html
      true -> [{ :versions, [String.to_atom("tlsv1.1")] }]
      _ -> []
    end

    opts = case Keyword.get(options, :cert) do
      [path: path] ->
        [{ :certfile, path } | opts]

      nil ->
        opts

      content ->
        [{ :cert, content } | opts]
     end

    opts = case Keyword.get(options, :key) do
      [path: path] ->
        [{ :keyfile, path } | opts]

      [rsa: content] ->
        [{ :key, { :RSAPrivateKey, content } } | opts]

      [dsa: content] ->
        [{ :key, { :DSAPrivateKey, content } } | opts]

      nil ->
        opts

      content ->
        [{ :key, { :PrivateKeyInfo, content } } | opts]
    end

    opts
  end

  defp ssl_accept(socket) do
    :ssl.ssl_accept(socket)
  end

  defp ssl_connect(host, port, options) do
    :ssl.connect(String.to_char_list(host), port, ssl_options(options), options[:timeout] || :infinity)
  end

  defp ssl_close(socket) do
    :ssl.close(socket)
  end
end
