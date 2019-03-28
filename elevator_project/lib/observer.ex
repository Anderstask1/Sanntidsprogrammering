defmodule NodeCollector do
@moduledoc """
This module contains functions for making a list of all nodes in a cluster.
"""

@doc """
Creates a list of tuples. Each tuple contains the name of a node, and its PID.
All nodes in the cluster is included in the created list, and they are also
sorted by IP.

"""

  def ip_to_string ip do
    :inet.ntoa(ip) |> to_string()
  end

  def get_full_name(ip) do
    s_ip = ip |> ip_to_string()
    "heis" <> "@" <> s_ip
  end

  def ip(node) do
    string = to_string(node)
    base = byte_size(":elevator@")-1
    new_string = binary_part(string, base, byte_size(string) -(base+1))
    :inet.parse_address(to_charlist(new_string))
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
    Enum.member?(NodeCollector.all_nodes, name)
  end

  @doc """
  Checks if the Node is the master.
  test list every 3rd second for changes in the list.
  """
  def is_master do
    if Node.self() == Enum.at(Enum.sort(all_nodes()), 0) do #yes
      IO.puts "Im master"
      IO.puts "send the list"
    end
  end

end

defmodule Beacon do
@moduledoc """
This module broadcasts a signal containing it self to other nodes on the same network.
"""
  use GenServer
  @beacon_port 45678
  @radar_port 45679

@doc """
start_link(port) boots a server process
"""
  def start_link(port \\ 45678) do
    GenServer.start_link(__MODULE__,port)
  end

  @doc """
  init(port) initialize the transmitter.
  The initialization runs inside the server process right after it boots
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
      :ok = :gen_udp.send(beaconSocket, {10,22,78,63}, 45679, "package" )
      beacon(beaconSocket)
    end
end

defmodule Radar do
@moduledoc """
This module receives a signal from a node, and add that node to the cluster.
"""
  use GenServer
  @radar_port 45679
  @doc """
  start_link(port) boots a server process
  """
  def start_link(port \\ 45679) do
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

    #receive do
    #  {msg, :gone} -> IO.puts "Received #{inspect msg}"
    #after 1 ->
    #  IO.puts("Radar did not receive")
    #end

    case :gen_udp.recv(radarSocket, 1000) do
      {:ok, {ip, _port, _data}} ->
        name = String.to_atom(NodeCollector.get_full_name(ip))
        Node.ping name
        case NodeCollector.node_in_list(name) do
          false ->
            case NodeCollector.is_master do
              true -> Nodes.get_list
            end


        #current = self()
        #Process.spawn_monitor(fn -> send(current,{self(), :gone}) end)

        #pid = pid(to_string(data))
        #case NodeCollector.node_in_list({ip, name, pid}) do
        #  false ->

        #    List_name_pid.add_to_list({ip, name, data})
        #    NodeCollector.is_master
            #IO.puts "I am data #{inspect data}
            #am i a binary? #{inspect is_binary(to_string(data))}
            #am i a list? #{inspect is_list(data)}
            #can i turn to PID? #{inspect pid(to_string(data))}"

            #IO.puts "spawne monitor something that is pid? #{inspect to_string(data)} "
            #IO.puts "Input for monitor: #{inspect pid(to_string(data))}"
            #pid_monitor = Process.monitor(pid(to_string(data)), true)

            #IO.puts "Monitor spawned with reference #{inspect pid_monitor} "
        #  true -> IO.puts "already in list"
        #monitor = Process.monitor(pid(to_string(data)))
        {:error, _} -> {:error, :could_not_receive}
      end
    radar(radarSocket)
  end
end

  def pid(string) when is_binary(string) do
    base = byte_size("#PID<")
    full = string
    new_string = binary_part(full, base, byte_size(full) - (base+1))
   :erlang.list_to_pid('<#{new_string}>')
  end

end

defmodule Nodes do
  use GenServer

  # create the genserver with an empty list
  def init do
    {:ok, _} = start_link()
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [Node.self()], name: :list_of_nodes)
  end

  def get_list do
    GenServer.multi_call([node() | Node.list()], :list_of_nodes, :get_list)
  end

  def add_to_list(name) do
    GenServer.cast(:list_of_nodes, {:add_to_list, name})
    #Enum.sort(get_list)
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


  # -------------CAST AND CALLS -----------------


  def handle_call(:get_list, _from, list) do
    {:reply, list, list}
  end

  def handle_cast({:add_to_list, name}, list) do
    {:noreply, list ++ [name]}
  end

end
#get_ip_of_bad_node
#delete_bad_nodes
#get_name_and_pid

defmodule Global_list do
  use GenServer

  def init do
    {:ok, _} = start_link()
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: :global_list)
  end

  def get_top do
    GenServer.call(:global_list, :pop)
  end

  def add(item) do
    GenServer.cast(:global_list, {:push, item})
  end

  def get_list do
    GenServer.multi_call([node() | Node.list()],:global_list, :pop)
  end


  #-----------
  def handle_call(:pop, _form, [head | tail]) do
    {:reply, head, tail}
  end

  def handle_cast({:push, item}, state) do
    {:noreply, [item | state]}
  end

end

defmodule Monitor do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
   GenServer.start_link(__MODULE__, [], opts)
 end

 def init(_) do
   :ok = :net_kernel.monitor_nodes(true)
   IO.puts "Monitoring!"
 end

 def handle_info({:nodedown, node}, retry_set) do
   Logger.info "Node #{node} is down"
   {:noreply, retry_set}
 end
end

defmodule Init do

  @moduledoc """
  This is the init module. The init module is setting up the system, doing the necessary initial
  config. This includes udp-broadcast to set up the cluster, spawning the modules and sending an empty
  list to all elevators.
  """

  def ip_to_string ip do
      :inet.ntoa(ip) |> to_string()
  end

  @doc """
  initializes a node. Gives it a name and makes it search for other nodes while
  it broadcasts itself.
  """
  def init(tick_time \\ 15000) do
    ip = Nodes.get_my_ip() |> ip_to_string()
    Node.start(String.to_atom("heis" <> "@" <> ip), :longnames, tick_time)
    Node.set_cookie :hello
    spawn fn -> Beacon.start_link() end
    spawn fn -> Radar.start_link end
    #:timer.sleep(2000)

    spawn fn -> Nodes.start_link() end

    #Nodes.add_to_list(self())
  end
end
