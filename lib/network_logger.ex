defmodule Logger.Backends.Network do
  alias Logger.Backends.Network.TCPClient

  @default_format "$time $metadata[$level] $message\n"

  def init(_) do
    if user = Process.whereis(:user) do
      Process.group_leader(self(), user)
      {:ok, configure([])}
    else
      {:error, :ignore}
    end
  end

  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  def handle_event({_level, gl, _event}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: min_level} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      log_event(level, msg, ts, md, state)
    end
    {:ok, state}
  end

  def terminate(_reason, %{output: {:udp, _host, _port, socket}}) do
    :gen_udp.close(socket)
    :ok
  end

  def terminate(_reason, %{output: {:tcp, client}}) do
    TCPClient.stop client
    :ok
  end

  ## Helpers

  defp configure(options, %{output: {:udp, _host, _port, socket}}) do
    :gen_udp.close(socket)
    configure(options)
  end

  defp configure(options, %{output: {:tcp, client}}) do
    TCPClient.stop client
    configure(options)
  end

  defp configure(options, _state) do
    configure(options)
  end

  defp configure(options) do
    network_logger = Keyword.merge(Application.get_env(:logger, :network_logger, []), options)
    Application.put_env(:logger, :network_logger, network_logger)

    level    = Keyword.get(network_logger, :level)
    metadata = Keyword.get(network_logger, :metadata, [])
    output   = Keyword.get(network_logger, :output, :console)
    format   = Keyword.get(network_logger, :format, @default_format)
    |> Logger.Formatter.compile()

    output = case output do
               :console -> :console
               {:udp, host, port} ->
                 {:ok, socket} = :gen_udp.open 0
                 host = host |> to_charlist
                 {:udp, host, port, socket}
               {:tcp, host, port} ->
                 host = host |> to_charlist
                 {:ok, tcp_client} = TCPClient.start_link(host, port)
                 {:tcp, tcp_client}
             end
    %{metadata: metadata, level: level, output: output, format: format}
  end

  defp log_event(level, msg, ts, md, %{metadata: metadata, format: format, output: :console}) do
    IO.puts format_event(level, msg, ts, md, metadata, format)
  end

  defp log_event(level, msg, ts, md, %{metadata: metadata, format: format, output: {:udp, host, port, socket}}) do
    log_msg = format_event(level, msg, ts, md, metadata, format)
    :gen_udp.send socket, host, port, [log_msg]
  end

  defp log_event(level, msg, ts, md, %{metadata: metadata, format: format, output: {:tcp, client}}) do
    log_msg = format_event(level, msg, ts, md, metadata, format)
    TCPClient.log_msg client, log_msg
  end

  # defp log_event(level, msg, ts, md, state) do
  #   # unkonwn opts
  #   IO.puts "unknown opts: #{inspect level}, #{inspect msg}, #{inspect ts}, #{inspect md}, #{inspect state}"
  # end

  defp format_event(level, msg, ts, metadata, keys, format) do
    Logger.Formatter.format(format, level, msg, ts, take_metadata(metadata, keys))
  end

  defp take_metadata(metadata, keys) do
    metadatas = Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error     -> acc
      end
    end)

    Enum.reverse(metadatas)
  end
end
