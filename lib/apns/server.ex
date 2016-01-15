defmodule APNSx.Server do
  @moduledoc """
    Simulates an APN server

    * Collect alls certificate verifications and channel messages.
    * Will accept any SSL connection (no real verification)
    * Support queued commands which will trigger behaviours when a client sends data
      * `:close` Will terminate the connection
      * `{:respond, data}` Will respond with the given data
  """
  use GenServer

  @doc """
    Starts a server using the `certfile` and `keyfile` pair as paths to load
    the SSL crypto and listens on `port`.
  """
  @spec start(String.t, String.t, non_neg_integer) :: {:ok, pid}
  def start(certfile, keyfile, port) do
    GenServer.start_link(__MODULE__, {certfile, keyfile, port})
  end

  def init({certfile, keyfile, port}) do
    server = self
    opts   = [certfile: certfile,
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
    {:ok, {[],[]}}
  end

  @doc """
    Retrieves all collected certificate verification calls and channel messages
    from `server` in order of their arrival
  """
  @spec retrieve_log(pid) :: [...]
  def retrieve_log(server) do
    GenServer.call(server, :retrieve_log)
  end

  @doc """
    Enqueues a command `cmd` which will be used for the next incoming
    channel message to the `server`
  """
  @spec queue_cmd(pid, any) :: :ok
  def queue_cmd(server, cmd) do
    GenServer.call(server, {:queue_cmd, cmd})
  end

  defp verify(server, payload) do
    GenServer.call(server, {:verify, payload})
  end

  def handle_call(:retrieve_log, _, {cmds, log}) do
    {:reply, Enum.reverse(log), {cmds, log}}
  end

  def handle_call({:queue_cmd, cmd}, _, {cmds, log}) do
    {:reply, :ok, {[cmd |cmds], log}}
  end

  def handle_call({:verify, {cert, result, user_state}}, _, {cmds, log}) do
    log = [{:cert, {cert, result}} | log]
    {:reply, {:valid, user_state}, {cmds, log}}
  end

  def handle_info({:ssl, _, data}, {[], log}) do
    log = [{:ssl, data} | log]
    {:noreply, {[], log}}
  end
  def handle_info({:ssl, ssl_socket, data}, {[cmd | cmds], log}) do
    log = [{:ssl, data} | log]
    case cmd do
      {:respond, data} ->
        :ok = :ssl.send(ssl_socket, data)
      :close ->
        :ok = :ssl.close(ssl_socket)
    end
    {:noreply, {cmds, log}}
  end
end
