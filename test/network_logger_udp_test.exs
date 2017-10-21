defmodule Logger.Backends.Network.UDPTest do
  use ExUnit.Case, async: false
  require Logger

  @backend {Logger.Backends.Network, :test}

  @message "Yo"
  @metadata []
  @level :debug

  setup_all do
    {:ok, server} = :gen_udp.open 0, [:binary, {:active, false}]
    {:ok, port} = :inet.port(server)
    config [level: @level, metadata: @metadata, output: {:udp, "localhost", port}]
    on_exit fn ->
      :gen_udp.close(server)
    end
    {:ok, server: server}
  end

  test "sends debug message via UDP", %{server: server}do
    Logger.debug @message
    assert {:ok, {_ip, _port, message}} = :gen_udp.recv(server, 0, 500)
    assert String.contains?(message, "[debug] Yo")
  end

  test "can change metadata", %{server: server} do
    new_metadata = [:pid]
    config [metadata: new_metadata]
    Logger.debug @message
    assert {:ok, {_ip, _port, message}} = :gen_udp.recv(server, 0, 500)
    assert String.contains?(message, "[debug] Yo")
    config [metadata: @metadata]
  end

  test "can use info level", %{server: server} do
    config [level: :info]
    Logger.debug @message
    assert {:error, :timeout} = :gen_udp.recv(server, 0, 500)
    Logger.info @message
    assert {:ok, {_ip, _port, message}} = :gen_udp.recv(server, 0, 500)
    assert String.contains?(message, "[info] Yo")
    config [level: @level]
  end

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
  end

end
