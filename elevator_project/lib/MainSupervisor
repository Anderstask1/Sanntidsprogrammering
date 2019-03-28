defmodule Main.Supervisor do

  use Supervisor
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
    IO.puts "heisann"
  end

  def init(_args) do
    IO.puts "her"
    #children = [
    #  {Monitor, []},
    #  {Network, [45679]},
    #  {Task.Supervisor, name: Auction.Supervisor}
    #  ]
    children = [
      %{
        id: Distributor,
        start: {Distributor, :start_link}
        #restart: when restart killed process,
        #shutdown: how to be terminated,
        #type: worker or supervisor (default worker)
      }
    ]

    opts = [strategy: :one_for_one]
    IO.puts "her"
    Supervisor.init(children, opts)
  end
end



defmodule Network do
  use Supervisor

  def start_link([recv_port]) do
    Supervisor.start_link(__MODULE__,[recv_port],  name: :network)
    IO.puts "VEL?"
  end

  def init([recv_port]) do
    IO.puts "her"
    children = [
      {UDP_Beacon, [recv_port]},
      {UDP_Radar, [recv_port]}
    ]
    IO.puts "nå?"
    Supervisor.init(children, strategy: :one_for_one)
    IO.puts "HERE"
  end
end


defmodule UDP_Beacon do
  use GenServer
  @beacon_port 45678
  @radar_port 45679

@doc """
start_link(port) boots a server process
"""
  def start_link(port \\ 45678) do
    IO.puts "yessir"
    GenServer.start_link(__MODULE__, port)
  end

  @doc """
  init(port) initialize the transmitter.
  The initialization runs inside the server process right after it boots
defmodule Observer do
  """
    def init(port) do
      {:ok, beaconSocket} = :gen_udp.open(45678, [active: false, broadcast: true])
      beacon(beaconSocket)
    end

  @doc """
  beacon(beaconSocket) takes in a socket number.
  It sleep for a random amount of time, and then beacons out its own information.
  Then it recall itself
  Changed from Node.self()
  10,22,77,209
  {inspect(self())}
  """
    def beacon(beaconSocket) do
      :timer.sleep(1000 + :rand.uniform(500))
      :ok = :gen_udp.send(beaconSocket, {10,100,23,242}, 45679, "package" )
      IO.puts "sent"
      beacon(beaconSocket)
    end
end

defmodule UDP_Radar do
  use GenServer
  @radar_port 45679
  @doc """
  start_link(port) boots a server process
  """
  def start_link(port \\ 45679) do
    IO.puts "yessir"
    GenServer.start_link(__MODULE__, port)
  end

  @doc """
  radar() initialize the reciever.
  """
  def init(port) do
    {:ok, radarSocket} = :gen_udp.open(port, [active: false, broadcast: true])
    radar(radarSocket)
  end

  @doc """
  radar(radarSocket) listen for messages sent to its socket.
  If it receive a message from a new node, it should add this node to the cluster.
Node.ping String.to_atom(to_string(data))
  """
  def radar(radarSocket) do
    case :gen_udp.recv(radarSocket, 1000) do
      {:ok, {ip, _port, data}} ->
        IO.puts "received"
        name = String.to_atom(NodeCollector.get_full_name(ip))
        Node.ping name
        case NodeCollector.node_in_list(name) do
          false ->
            case NodeCollector.am_I_master do
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
   GenServer.start_link(__MODULE__, [], opts)
 end

 def init([]) do
   :ok = :net_kernel.monitor_nodes(true)
   IO.puts "Monitoring!"
   {:ok, state}
 end

 def handle_info({:nodedown, node_name}, state) do
   IO.puts("NODE DOWN#{node_name}")

 end

end
