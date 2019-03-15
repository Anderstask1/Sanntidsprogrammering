defmodule Observer do

  def hello do
      IO.puts"Hello brothers"
      :world
  end

  use GenServer
"@BEACON_PORT 45678
@RADAR_PORT 45679"

@doc """
start_link create a new server process.
It takes in the parameter 'port', which defaults to 45678.
"""
  def start_link(port \\ 45678) do
    GenServer.start_link(__MODULE__, port) # Start 'er up
  end


@doc """
init(port) initialize the transmitter.
The initialization runs inside the server process right after it boots
"""
  def init(port) do
    IO.puts "IN INIT"
    {state, socket} = :gen_udp.open(port, [active: false, broadcast: true])
    beacon(state, socket)
  end

@doc """
beacon(state, socket) takes in a state and a socket.
The function takes appropriate action depending on the state.
If state is :ok, then the fuction beacon out its own information
If state is :error, then the function tries to reboot the system.
"""
  def beacon(state, socket) do
    IO.puts "IN BEACON"
    :timer.sleep(1000 + :rand.uniform(500))
    :gen_udp.send(socket, {255,255,255,255}, 45679, Node.self())

  end

@doc """
radar() initialize the reciever.
"""
  def radar() do
    {State, RadarSocket} = :gen_udp.open(45679, [:binary, active: false])
    radar({State, RadarSocket})
  end
@doc """
radar(state, RadarSocket) is first called by radar(), and later called by itself.
It listen for messages from other nodes.
If it receive a message from a new node, it should add this node to a list.
"""
  def radar({:ok, RadarSocket}) do
    {:ok, {IPadresse, Port, Node_encoded}} = :gen_udp.recv(RadarSocket, 0)
  end

end
