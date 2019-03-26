#https://medium.com/blackode/quick-easy-tcp-genserver-with-elixir-and-erlang-10189b25e221
#https://elixir-lang.org/getting-started/mix-otp/task-and-gen-tcp.html

defmodule Client do
  def pang do
    {:ok, socket} = :gen_udp.open(30000, [:binary, {:active, true}])
    :ok = :gen_udp.send(socket, {10,100,23,242}, 20014,"hello")
                        #String.to_char_list("pang") |> :erlang.term_to_binary)

    value = receive do
      {:udp, _socket,_, _, bin} ->
        :io.format("Client received binary = ~p~n", [bin])
        str = :erlang.binary_to_term(bin)
        :io.format("Client result = ~p~n", [str])
        {:ok, str}
      data ->
        IO.puts("noe skjedde")
        IO.inspect data
    after
      5_000 -> :error
    end

    :gen_udp.close(socket)
    value
  end
end

#https://daruiapprentice.blogspot.com/2016/04/using-gen-udp-module-in-elixir.html
defmodule UDPserver do
  def start_server do
    {:ok, socket} = :gen_udp.open(4321, [:binary])
    # IO.puts "ok: #{:ok}"
    # IO.puts "Socket : #{socket}"
    # IO.puts "GG"

    loop()
  end

  defp loop do
    receive do
      {:udp, socket, host, port, bin} ->
        :io.format("server receive binary = ~p~n", [bin])
        str = :erlang.binary_to_term(bin)
        :io.format("server unpacked = ~p~n", [str])
        :gen_udp.send(socket, host, port, :erlang.term_to_binary('pong'))
        loop()
    end
  end
end

defmodule SimpleUdpClient do
  def ping do
    {:ok, socket} = :gen_udp.open(30000, [:binary])
    :ok = :gen_udp.send(socket, 'localhost', 1234,
                        String.to_char_list("ping") |> :erlang.term_to_binary)

    value = receive do
      {:udp, _socket, _, _, bin} ->
        :io.format("Client received binary = ~p~n", [bin])
        str = :erlang.binary_to_term(bin)
        :io.format("Client result = ~p~n", [str])
        {:ok, str}
    after
      2_000 -> :error
    end

    :gen_udp.close(socket)
    value
  end
end
