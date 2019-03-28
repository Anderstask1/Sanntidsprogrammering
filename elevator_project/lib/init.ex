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
    full_name = "heis" <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
    Node.set_cookie :hello
    a = self()

    #spawn fn -> Beacon.start_link(a) end
    spawn fn -> Radar.start_link end
    #:timer.sleep(2000)

    spawn fn -> Nodes.start_link() end
    spawn fn -> Global_list.start_link end

    #Nodes.add_to_list(self())
  end
end
