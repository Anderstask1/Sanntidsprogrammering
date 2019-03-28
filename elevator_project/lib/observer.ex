defmodule NodeCollector do
@moduledoc """
This module contains functions for making a list of all nodes in a cluster.
"""

@doc """
Creates a list of tuples. Each tuple contains the name of a node, and its PID.
All nodes in the cluster is included in the created list, and they are also
sorted by IP.

"""

  def hello do
    :world
  end

  def ip_to_string ip do
    :inet.ntoa(ip) |> to_string()
  end

  def get_full_name(ip) do
    s_ip = ip |> ip_to_string()
    "heis" <> "@" <> s_ip
  end

  def list_of_nodes do
    sorted_list = all_nodes() |> Enum.sort
    for each_node <- sorted_list, do: {each_node, ip(each_node) |> elem(1) }
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
      [:"nonode@nohost"] -> {:error, :node_not_running}
      nodes -> nodes
    end
  end

  def node_in_list(name) do
    Enum.member?(NodeCollector.all_nodes, name)
  end

  def is_list_the_same do
    list = Nodes.get_list()
    :timer.sleep(3000)
    Enum.sort(list) == Enum.sort(Nodes.get_list())
  end




  @doc """
  Checks if the Node is the master.
  test list every 3rd second for changes in the list.
  """
  def am_I_master do
    if Node.self() == Enum.at(Enum.at(Nodes.get_list(),0),1) do #yes
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
  def start_link(pid) do
    GenServer.start_link(__MODULE__,pid)
  end

  @doc """
  init(port) initialize the transmitter.
  The initialization runs inside the server process right after it boots
  """
    def init(pid) do
      {:ok, beaconSocket} = :gen_udp.open(@beacon_port, [active: false, broadcast: true])
      beacon(pid, beaconSocket)
    end

  @doc """
  beacon(beaconSocket) takes in a socket number.
  It sleep for a random amount of time, and then beacons out its own information.
  Then it recall itself
  Changed from Node.self()
  10,22,77,209
  {inspect(self())}
  """
    def beacon(pid, beaconSocket) do
      :timer.sleep(1000 + :rand.uniform(500))
      :ok = :gen_udp.send(beaconSocket, {10,100,23,180}, @radar_port, "#{inspect pid}" )
      beacon(pid, beaconSocket)
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
  def start_link(port \\ @radar_port) do
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
    #  msg -> IO.puts "Received #{inspect msg}"
    #after 1 ->
    #end
    case :gen_udp.recv(radarSocket, 1000) do
      {:ok, {ip, _port, _}} ->
        name = String.to_atom(NodeCollector.get_full_name(ip))
        Node.ping name
      {:error, _} -> {:error, :could_not_receive}
    end
    radar(radarSocket)
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
    GenServer.start_link(__MODULE__, [], name: :list_of_nodes)
  end

  def get_list do
    GenServer.multi_call([node() | Node.list()],:list_of_nodes, :get_list)
  end

  def add_to_list(name) do
    GenServer.cast(:list_of_nodes, {:add_to_list, name})
    #Enum.sort(get_list)
  end

  # -------------CAST AND CALLS -----------------

  def handle_call(:get_list, _from, list) do
    {:reply, list, list}
  end

  def handle_cast({:add_to_list, name}, list) do
    {:noreply, list ++ name}
  end

end
#get_ip_of_bad_node
#delete_bad_nodes
