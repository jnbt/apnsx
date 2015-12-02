defmodule APNSx.Connection do
  use GenServer
  require Logger

  def start(host, port, options) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok)
    :ok = GenServer.call(pid, {:connect, host, port, options})
    {:ok, pid}
  end

  def write(pid, data) do
    :ok = GenServer.call(pid, {:write, data})
    {:ok, pid}
  end

  def close(pid) do
    :ok = GenServer.call(pid, :close)
    {:ok, pid}
  end

  def handle_call({:connect, host, port, options}, {user, _}, _) do
    :ssl.start()
    Logger.debug("Connecting to: #{host}:#{port}, #{inspect(options)}")
    {:ok, socket} = ssl_connect_with_options(host, port, options)
    :ok = :ssl.ssl_accept(socket)
    Logger.debug("Connected: #{inspect(:ssl.connection_info(socket))}")
    {:reply, :ok, {user, socket}}
  end

  def handle_call({:write, data}, _, {user, socket}) do
    Logger.debug("[SEND] #{inspect(data)}")
    :ok = :ssl.send(socket, data)
    {:reply, :ok, {user, socket}}
  end

  def handle_call(:close, _, {user, socket}) do
    Logger.debug("Closing connection")
    :ok = :ssl.close(socket)
    {:reply, :ok, {user, socket}}
  end

  def handle_info({:ssl_closed, _}, {user, socket}) do
    Logger.debug("Connection closed")
    send(user, :closed)
    {:stop, :normal, {user, socket}}
  end

  def handle_info({:ssl_error, _, reason}, {user, socket}) do
    Logger.debug("Connection error: #{reason}")
    send(user, {:error, reason})
    {:stop, :error, {user, socket}}
  end

  def handle_info({:ssl, _, data}, {user, socket}) do
    Logger.debug("[RECV] #{inspect(data)}")
    send(user, {:recv, data})
    {:noreply, {user, socket}}
  end

  defp ssl_connect_with_options(host, port, options) do
    ssl_options = APNSx.Connection.SSLOptions.normalize(options)
    timeout = options[:timeout] || :infinity
    :ssl.connect(String.to_char_list(host), port, ssl_options, timeout)
  end

  defmodule SSLOptions do
    def normalize(options) do
      opts = []

      opts = case Keyword.get(options, :versions) do
        # Allow TLS v1, v1.1, v1.2 as a workaround for an OTP SSL
        # See
        # * https://github.com/inaka/apns4erl/pull/65
        # * http://erlang.org/pipermail/erlang-questions/2015-June/084935.html
        nil -> [{ :versions, [:"tlsv1", :"tlsv1.1", :"tlsv1.2"] } | opts]
        versions -> [{:versions, versions} | opts]
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

      opts = case Keyword.get(options, :password) do
        nil -> opts
        content when is_binary(content) ->
          chars = String.to_char_list(content)
          [{:password, chars} | opts]
        content -> [{:password, content} | opts]
      end

      opts
    end
  end
end
