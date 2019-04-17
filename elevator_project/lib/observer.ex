defmodule Init do
  def init(tick_time \\ 15000) do
    ip = Utilities.get_my_ip() |> Utilities.ip_to_string()
    full_name = "heis" <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
    Node.set_cookie :hello
    Main.Supervisor.start_link([])
  end
end


defmodule Utilities do

  def ip_to_string(ip) do
      :inet.ntoa(ip) |> to_string()
  end

  def get_my_ip do
    {:ok, socket} = :gen_udp.open(6789, [active: false, broadcast: true])
    :ok = :gen_udp.send(socket, {255,255,255,255}, 6789, "test packet")
    ip = case :gen_udp.recv(socket, 100, 1000) do
      {:ok, {ip, _port, _data}} -> ip
      {:error, _} -> {:error, :could_not_get_ip}
    end
    :gen_udp.close(socket)
    ip
  end

  def get_full_name(ip) do
    s_ip = ip |> ip_to_string()
    "heis" <> "@" <> s_ip
  end

  @doc """
  Returns all nodes in the cluster
  """
    def all_nodes do
      case [Node.self | Node.list] do
        nodes -> nodes
      end
    end

    def node_in_list(name) do
      Enum.member?(all_nodes(), name)
    end

    def am_I_master do
      Node.self() == Enum.at(Enum.sort(all_nodes()), 0)
    end

end

# defmodule Init.Application do
#     use Application
#
#     def start() do
#         children = [
#             {Main.Supervisor, []}
#         ]
#         {:ok, _} = Supervisor.start_link(children,strategy: :one_for_one)
#     end
#
# end

defmodule Main.Supervisor do
  # Automatically defines child_spec/1
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Monitor, []},
      {UDP_Beacon, [45676]},
      {UDP_Radar, [45677]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule UDP_Beacon do
  use Task


  def start_link(port) do
    Task.start_link(__MODULE__, :init, port)
  end

  def init(port) do
    {:ok, beaconSocket} = :gen_udp.open(port, [active: false, broadcast: true])
    beacon(beaconSocket)
  end


  def beacon(beaconSocket) do
    :timer.sleep(1000 + :rand.uniform(500))
    :ok = :gen_udp.send(beaconSocket, {255,255,255,255}, 45677, "package" )
    beacon(beaconSocket)
  end
end

defmodule UDP_Radar do
  use Task

  def start_link(port) do
    Task.start_link(__MODULE__, :init, port)
  end


  def init(port) do
    {:ok, radarSocket} = :gen_udp.open(port, [active: false, broadcast: true])
    radar(radarSocket)
  end


  def radar(radarSocket) do
    case :gen_udp.recv(radarSocket, 1000) do
      {:ok, {ip, _port, _data}} ->
        name = String.to_atom(Utilities.get_full_name(ip))
        Node.ping name
      {:error, _} -> {:error, :could_not_receive}
    end
    radar(radarSocket)
  end

end

defmodule Monitor do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
   GenServer.start_link(__MODULE__, opts, name: __MODULE__)
 end

 @impl true
 def init(state) do
    IO.puts "Monitoring!"
   :ok = :net_kernel.monitor_nodes(true)
   {:ok, state}
 end

 def handle_info({:nodedown, node_name}, state) do
    IO.puts("NODE DOWN #{node_name}")
    Distributor.delete_from_complete_list(node_name)
    {:noreply, state}
  end

  def handle_info({:nodeup, node_name}, state) do
    :timer.sleep(3000)
    # IO.puts("MY LIST #{inspect Distributor.get_complete_list()}")
     Distributor.add_to_complete_list(Distributor.get_elevator_in_complete_list(Node.self(), Distributor.get_complete_list()), Node.self())
     {:noreply, state}
   end

end
