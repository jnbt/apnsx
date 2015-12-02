defmodule APNSx.ConnectionTest do
  use ExUnit.Case, async: true
  alias APNSx.Connection
  alias APNSx.ConnectionTest.APNServer

  @server_cert Path.expand("../fixtures/server-cert.pem", __DIR__)
  @server_key Path.expand("../fixtures/server-key.pem", __DIR__)

  @client_cert_plain Path.expand("../fixtures/client-cert.plain.pem", __DIR__)
  @client_key_plain Path.expand("../fixtures/client-key.plain.pem", __DIR__)
  @client_cert_enc Path.expand("../fixtures/client-cert.enc.pem", __DIR__)
  @client_key_enc Path.expand("../fixtures/client-key.enc.pem", __DIR__)
  @password "asdf"

  setup_all do
    :ssl.start()
    Logger.remove_backend :console
    on_exit fn ->
      Logger.add_backend :console
    end
    :ok
  end

  setup %{port: port} do
    {:ok, server} = APNServer.start(@server_cert, @server_key, port)
    {:ok, [server: server, port: port]}
  end

  @tag port: 9090
  test "connects to SSL server using a client cert with encrypted key",
       %{server: server, port: port} do
    opts = [cert: [path: @client_cert_enc],
            key: [path: @client_key_enc],
            password: @password]

    test_connection(server, port, opts)
  end

  @tag port: 9091
  test "connects to SSL server using a client cert with plain key",
       %{server: server, port: port} do
    opts = [cert: [path: @client_cert_plain],
            key: [path: @client_key_plain],
            password: nil]
    test_connection(server, port, opts)
  end

  defp test_connection(server, port, opts) do
    {:ok, connection} = Connection.start("127.0.0.1", port, opts)
    Connection.write(connection, 'PLEASE RESPOND')
    [{:recv, 'YOUR RESPONSE'}, :closed] = simulate_client(connection, [])

    [{:cert, {_, result}}, {:ssl, msg1}, {:ssl, msg2}] = APNServer.log(server)
    assert {:bad_cert, :selfsigned_peer} == result, "must be a self signed cert"
    assert 'PLEASE RESPOND' == msg1
    assert 'PLEASE CLOSE' == msg2
  end


  # Simulates a client which first waits for 'YOUR RESPONSE' to respond
  # with 'PLEASE CLOSE'. Returns the collected list of received messages when
  # the connection is closed
  defp simulate_client(connection, log) do
    receive do
      msg ->
        log = [msg | log]
        case msg do
          {:recv, 'YOUR RESPONSE'} ->
            Connection.write(connection, 'PLEASE CLOSE')
            simulate_client(connection, log)
          :closed -> Enum.reverse(log)
          _ -> simulate_client(connection, log)
        end
    end
  end

  # Simulates an APN server which waits for 'PLEASE RESPOND' to answer with
  # 'YOUR RESPONSE'. When 'PLEASE CLOSE' is received the connection is closed.
  # Collect alls certificate verifications and channel messages
  defmodule APNServer do
    use GenServer

    def start(certfile, keyfile, port) do
      GenServer.start_link(__MODULE__, {certfile, keyfile, port})
    end

    def init({certfile, keyfile, port}) do
      server = self
      opts = [certfile: certfile,
              keyfile: keyfile,
              reuseaddr: true,
              verify: :verify_peer,
              verify_fun: {fn(a,b,c) -> verify(server, {a,b,c}) end, nil}]
      {:ok, listen_socket} = :ssl.listen(port, opts)
      Task.start fn ->
        {:ok, socket} = :ssl.transport_accept(listen_socket)
        :ok = :ssl.ssl_accept(socket)
        :ssl.controlling_process(socket, server)
      end
      {:ok, []}
    end

    def log(server) do
      GenServer.call(server, :log)
    end

    def verify(server, payload) do
      GenServer.call(server, {:verify, payload})
    end

    def handle_call(:log, _, log) do
      {:reply, Enum.reverse(log), log}
    end

    def handle_call({:verify, {cert, result, user_state}}, _, log) do
      log = [{:cert, {cert, result}} | log]
      {:reply, {:valid, user_state}, log}
    end

    def handle_info({:ssl, ssl_socket, data}, log) do
      log = [{:ssl, data} | log]
      case data do
        'PLEASE RESPOND' ->
          :ok = :ssl.send(ssl_socket, 'YOUR RESPONSE')
        'PLEASE CLOSE' ->
          :ok = :ssl.close(ssl_socket)
      end
      {:noreply, log}
    end
  end
end
