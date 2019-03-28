
defmodule Utilities do

    def ip_to_string ip do
      :inet.ntoa(ip) |> to_string()
    end

    def get_full_name(ip) do
      s_ip = ip |> ip_to_string()
      full_name = "heis" <> "@" <> s_ip
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
      Enum.member?(all_nodes, name)
    end

    def am_I_master do
      Node.self() == Enum.at(Enum.sort(all_nodes), 0)
    end

end

defmodule Init.Application do
    use Application

    def start() do
        children = [
            {Main.Supervisor, []}
        ]
        {:ok, pid} = Supervisor.start_link(children,strategy: :one_for_one)
    end

end

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
      {UDP_Beacon, [45678]},
      {UDP_Radar, [45679]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule UDP_Beacon do
  use Task


  def start_link(port) do
    IO.puts "yessir"
    Task.start_link(__MODULE__, :init, port)
  end

  @impl true
  def init(port) do
    {:ok, beaconSocket} = :gen_udp.open(port, [active: false, broadcast: true])
    beacon(beaconSocket)
  end


  def beacon(beaconSocket) do
    :timer.sleep(1000 + :rand.uniform(500))
    :ok = :gen_udp.send(beaconSocket, {10,22,78,63}, 45679, "package" )
    IO.puts "sent"
    beacon(beaconSocket)
  end
end

defmodule UDP_Radar do
  use Task

  def start_link(port) do
    IO.puts "yessir"
    Task.start_link(__MODULE__, :init, port)
  end


  @impl true
  def init(port) do
    {:ok, radarSocket} = :gen_udp.open(port, [active: false, broadcast: true])
    radar(radarSocket)
  end


  def radar(radarSocket) do
    case :gen_udp.recv(radarSocket, 1000) do
      {:ok, {ip, _port, data}} ->
        IO.puts "received"
        name = String.to_atom(Utilities.get_full_name(ip))
        Node.ping name
        case Utilities.node_in_list(name) do
          false ->
            case Utilities.am_I_master do
              true -> Nodes.get_list
            end
          end
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
   IO.puts("NODE DOWN#{node_name}")

 end

end
#  {Task.Supervisor, name: Auction.Supervisor}
