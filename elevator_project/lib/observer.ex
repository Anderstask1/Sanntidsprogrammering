defmodule NodeCollector do
@moduledoc """
This is a module for creating and testing code that later can be used in the
Observer module
"""

@doc """
spm:

How to use observer.ex in init.ex
How to sort the nodes
global variables <8)
"""

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

@doc """
Works
"""
  def ip_to_string ip do
      :inet.ntoa(ip) |> to_string()
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

@doc """
boots a new node.
"""
  def boot_node(node_name, tick_time \\ 15000) do
    ip = get_my_ip() |> ip_to_string()
    full_name = node_name <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
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
      {:ok, beaconSocket} = :gen_udp.open(port, [active: true, broadcast: true])
      beacon(beaconSocket)
    end

  @doc """
  beacon(beaconSocket) takes in a socket number.
  It sleep for a random amount of time, and then beacons out its own information.
  Then it recall itself
  """
    def beacon(beaconSocket) do
      :timer.sleep(1000 + :rand.uniform(500))
      :ok = :gen_udp.send(beaconSocket, {10,22,77,37}, 45679, to_string(Node.self()))
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
  """
  def radar(radarSocket) do
    case :gen_udp.recv(radarSocket, 1000) do
      {:ok, {_ip, _port, data}} -> Node.ping String.to_atom(to_string(data))
      {:error, _} -> {:error, :could_not_receive}
    end
    radar(radarSocket)
  end



end
