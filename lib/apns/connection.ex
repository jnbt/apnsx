defmodule APNSx.Connection do

  def start do
    :ssl.start()
  end

  def open(host, port, options) do
    case ssl_connect(host, port, options) do
      {:ok, socket} ->
        :ssl.ssl_accept(socket)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def send(socket, message) do
    :ok = :ssl.send(message)
    {:ok, socket}
  end

  def close(socket) do
    :ok = :ssl.close(socket)
    :ok
  end

  def ssl_options(options) do
    # Force TLS v1.1 as a workaround for an OTP SSL bug
    # See
    # * https://github.com/inaka/apns4erl/pull/65
    # * http://erlang.org/pipermail/erlang-questions/2015-June/084935.html
    opts = [{ :versions, [String.to_atom("tlsv1.1")] }]

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

  defp ssl_connect(host, port, options) do
    :ssl.connect(String.to_char_list(host), port, ssl_options(options), options[:timeout] || :infinity)
  end
end
