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
    full_name = "heis" <> "@" <> s_ip
  end

  def list_of_nodes do
    sorted_list = all_nodes |> Enum.sort
    for each_node <- sorted_list, do: tuple = {each_node, pid(each_node) |> elem(1) }
  end

  def pid(node) do
    pid = Node.spawn_link node, fn ->
      receive do
        {:ping, client} -> send client, :pong
      end
    end
    send pid, {:ping, self()}
  end


@doc """
Returns all nodes in the cluster
"""
  def all_nodes do
    case [Node.self | Node.list] do
      [:'nonode@nohost'] -> {:error, :node_not_running}
      nodes -> nodes
    end
  end

  def node_in_list(node) do
    Enum.member?(all_nodes, node)
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
    GenServer.start_link(__MODULE__, port)
  end

  @doc """
  init(port) initialize the transmitter.
  The initialization runs inside the server process right after it boots
  """
    def init(port) do
      IO.puts "init beacon"
      {:ok, beaconSocket} = :gen_udp.open(port, [active: false, broadcast: true])
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
      :ok = :gen_udp.send(beaconSocket, {10,100,23,254}, 45679, "hei" )
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
    case :gen_udp.recv(radarSocket, 1000) do
      {:ok, {ip, _port, data}} ->
        name = String.to_atom(NodeCollector.get_full_name(ip))
        Node.ping name
        #case  not NodeCollector.node_in_list(name) do
        #false -> List_name_pid.add_to_list({name, data})
        #end
      {:error, _} -> {:error, :could_not_receive}
    end
    radar(radarSocket)
  end

end

defmodule List_name_pid do

  # create the genserver with an empty list
  def init do
    {:ok, _} = start()
  end

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: :genserver)
  end

  def get_list do
    GenServer.call(:genserver, :get_list)
  end

  def add_to_list({name, pid}) do
    GenServer.cast(:genserver, {:add_to_list, {name, pid}})
  end

  # -------------CAST AND CALLS -----------------

  def handle_call(:get_list, _from, list) do
    {:reply, list, list}
  end

  def handle_cast({:add_to_list, {name, pid}}, list) do
    {:noreply, list ++ [{name, pid}]}
  end
end
