defmodule APNSx.ConnectionTest do
  use ExUnit.Case, async: true
  alias APNSx.Connection
  alias APNSx.Server

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
    {:ok, server} = Server.start(@server_cert, @server_key, port)
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
    Server.queue_cmd(server, {:respond, 'YOUR RESPONSE'})
    Connection.write(connection, 'PLEASE RESPOND')
    assert [{:recv, 'YOUR RESPONSE'}, :closed] == simulate_client(connection, server, [])

    [{:cert, {_, result}}, {:ssl, msg1}, {:ssl, msg2}] = Server.retrieve_log(server)
    assert {:bad_cert, :selfsigned_peer} == result, "must be a self signed cert"
    assert 'PLEASE RESPOND' == msg1
    assert 'PLEASE CLOSE' == msg2
  end


  # Simulates a client which first waits for 'YOUR RESPONSE' to respond
  # with 'PLEASE CLOSE'. Returns the collected list of received messages when
  # the connection is closed
  defp simulate_client(connection, server, log) do
    receive do
      msg ->
        log = [msg | log]
        case msg do
          {:recv, 'YOUR RESPONSE'} ->
            Server.queue_cmd(server, :close)
            Connection.write(connection, 'PLEASE CLOSE')
            simulate_client(connection, server, log)
          :closed -> Enum.reverse(log)
          _ -> simulate_client(connection, server, log)
        end
    end
  end
end
