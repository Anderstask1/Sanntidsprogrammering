defmodule NodeCollector do
@moduledoc """
This module contains functions for making a list of all nodes in a cluster.
"""

@doc """
Creates a list of tuples. Each tuple contains the name of a node, and its PID.
All nodes in the cluster is included in the created list, and they are also
sorted by IP.
"""
  def get_full_name(ip) do
    s_ip = ip |> ip_to_string()
    full_name = "heis" <> "@" <> s_ip
  end

  def list_of_nodes do
    sorted_list = all_nodes |> Enum.sort
    for each_node <- sorted_list, do: tuple = {each_node, self()}
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
      {:ok, beaconSocket} = :gen_udp.open(port, [active: false, broadcast: true])
      beacon(beaconSocket)
    end

  @doc """
  beacon(beaconSocket) takes in a socket number.
  It sleep for a random amount of time, and then beacons out its own information.
  Then it recall itself
  Changed from Node.self()
  """
    def beacon(beaconSocket) do
      :timer.sleep(1000 + :rand.uniform(500))
      :ok = :gen_udp.send(beaconSocket, {10,100,23,180}, 45679, to_string(self())
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
      {:ok, {ip, _port, data}} -> Node.ping String.to_atom(get_full_name(ip))
      {:error, _} -> {:error, :could_not_receive}
    end
    radar(radarSocket)
  end
end
