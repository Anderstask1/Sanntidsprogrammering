defmodule Observer do
@moduledoc """
This is the observer. It should send out its own information while it listen for
other nodes as well. When it detects a new node, this node should be added to a
sorted list of nodes. The list is sorted by IP-adresses. The node on the top of
the list should send the list to its distributor.
How does the old distributor know that it is no longer the master?

spm:
How do I make the beacon send out a signal to "everyone"?
How do I make the radar listen for "everything"?
What do I do in def start_link?
How do they cluster?
How do I make something public?
"""
  def hello do
      IO.puts"Hello brothers"
      :world
  end

  use GenServer
"@BEACON_PORT 45678
@RADAR_PORT 45679"

@doc """
start_link create a new server process, and spawns a function.
It takes in the parameter 'port', which defaults to 45678.
"""
  def start_link(port \\ 45678) do
    Task.start_link(fn -> radar() end)
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
"""
  def beacon(beaconSocket) do
    :timer.sleep(1000 + :rand.uniform(500))
    :ok = :gen_udp.send(beaconSocket, {255,255,255,255}, 45679, "test")
    beacon(beaconSocket)
  end

@doc """
radar() initialize the reciever.
"""
  defp radar() do
    {:ok, radarSocket} = :gen_udp.open(45679, [active: false, broadcast: true])
    radar(radarSocket)
  end

@doc """
radar(radarSocket) listen for messages sent to its socket.
If it receive a message from a new node, it should add this node to a list.
"""
  def radar(radarSocket) do
    ip = case :gen_udp.recv(radarSocket, 1000) do
      {:ok, {ip, _port, data}} -> ip
      {:error, _} -> {:error, :could_not_receive}
    end
    ip_to_string(ip)
    radar(radarSocket)
  end
end


defmodule NodeCollector do
@@moduledoc """
This is a module for creating and testing code that later can be used in the
Observer module
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

  def ip_to_string ip do
      :inet.ntoa(ip) |> to_string()
    end

  def all_nodes do
    case [Node.self | Node.list] do
      [:'nonode@nohost'] -> {:error, :node_not_running}
      nodes -> nodes
    end
  end

  def boot_node(node_name, tick_time \\ 15000) do
    ip = get_my_ip() |> ip_to_string()
    full_name = node_name <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
  end

end
