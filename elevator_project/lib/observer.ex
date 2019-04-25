defmodule Init do
  def init(tick_time \\ 15000) do
    ip = Utilities.get_my_ip() |> Utilities.ip_to_string()
    full_name = "heis" <> "@" <> ip
    IO.puts("Full name #{inspect full_name}")
    resp = Node.start(String.to_atom(full_name), :longnames, tick_time)
    IO.puts("Node.start returns  #{inspect resp}")
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
    IO.puts("Calling Supervisor.start_link with argument #{inspect init_arg} and #{inspect __MODULE__}")
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Monitor, []},
      {UDP_Beacon, [45676]},
      {UDP_Radar, [45677]}
    ]
    IO.puts("Spawning Monitor, UDP_Beacon and UDP_Radars")
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule UDP_Beacon do
  use Task


  def start_link(port) do
    Task.start_link(__MODULE__, :init, port)
  end

  def init(port) do
    IO.puts("[INFO] init(port) and the port is #{inspect port}")
	case :gen_udp.open(port, [active: false, broadcast: true]) do
		{:ok, beaconSocket}->
			beacon(beaconSocket)
		unexpected ->
			IO.puts("[ERROR] unexpected return open UDP_Beacon port -> #{inspect unexpected}")
	end
  end


  def beacon(beaconSocket) do
	case :gen_udp.send(beaconSocket, {255,255,255,255}, 45677, "package" ) do
		:ok ->
			beacon(beaconSocket)
		unexpected ->
			IO.puts("[ERROR] unexpected return when sending UDP_Beacon port -> #{inspect unexpected}")
			IO.puts("The network connection is down :(")
			IO.puts("Taking all the orders from the system trying again in 5 seconds")
			WatchdogList.restart()
			WatchdogList.add_to_watchdog_list(Node.self())
			complete_system = Distributor.get_complete_list()
			Enum.each(complete_system, fn elev ->
				if elev.ip != Node.self() do
					Distributor.delete_from_complete_list(elev)
				end
			end)
			Enum.each(complete_system, fn elev ->
				if elev.ip != Node.self() do
					Enum.each(elev.orders, fn order ->
						Distributor.send_order(order, Node.self())
					end)
				end
			end)

			:timer.sleep(5000)
			beacon(beaconSocket)
	end

  end
end

defmodule UDP_Radar do
  use Task

  def start_link(port) do
    Task.start_link(__MODULE__, :init, port)
  end


  def init(port) do
	case :gen_udp.open(port, [active: false, broadcast: true]) do
		{:ok, radarSocket}->
			radar(radarSocket)
		unexpected ->
			IO.puts("[ERROR] unexpected return open UDP_Radar port -> #{inspect unexpected}")
	end
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
    IO.puts("NODE DOWN -> #{node_name} redistributing its orders")
	complete_system = Distributor.get_complete_list()
	Distributor.delete_from_complete_list(node_name)
	Enum.each(complete_system, fn elev ->
		if elev.ip != node_name do
			Enum.each(elev.orders, fn order ->
				Distributor.send_order(order, Node.self())
			end)
		end
	end)
    {:noreply, state}
  end

  def handle_info({:nodeup, node_name}, state) do
    :timer.sleep(3000)
     Distributor.add_to_complete_list(Distributor.get_elevator_in_complete_list(Node.self(), Distributor.get_complete_list()), Node.self())
     {:noreply, state}
   end

end
