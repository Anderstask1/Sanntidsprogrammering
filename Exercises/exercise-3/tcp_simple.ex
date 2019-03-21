defmodule TCP do
  def ping do
    {:ok, socket} = :gen_tcp.connect({10,100,23,242}, 33546, [:binary])
    # data = {"id" => 1, "method" => "Responder.Status", "params" => [""]}

    # :ok = :gen_tcp.close(socket)


    value = receive do

       {:tcp, _socket, bin} ->
         :io.format("Client received binary = ~p~n", [bin])
         str = to_string(bin)
         IO.puts str
         {:ok}
         receive_acks(socket)
    after
      5_000 -> :error
    end
  end

  def receive_acks(socket) do
    IO.puts "entered recieve_acks"
    str = IO.gets("Introduce string ") |> String.trim
    if str == "exit" do
      receive_acks(socket,:xD)
    else

      :ok = :gen_tcp.send(socket,str <> "\0")
      value = receive do
        {:tcp, _socket, bin} ->
          :io.format("Client received binary = ~p~n", [bin])
          str = to_string(bin)
          IO.puts str
          {:ok}
          receive_acks(socket)
        end
      end
    end
    def receive_acks(socket,:xD) do
      :ok = :gen_tcp.close(socket)
      :ok
    end
end
