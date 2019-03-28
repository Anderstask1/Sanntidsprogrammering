defmodule Init.Application do

  @moduledoc """
  This is the init module. The init module is setting up the system, doing the necessary initial
  config. This includes udp-broadcast to set up the cluster, spawning the modules and sending an empty
  list to all elevators.
  """
  use Application

  def start() do
    children = [
      {Main.Supervisor, []}
    ]

    opts = [strategy: :one_for_one]
    IO.puts "here2"
    {:ok, pid} = Supervisor.start_link(children,opts)
  end

end

defmodule Init_1 do

  def ip_to_string(ip) do
      :inet.ntoa(ip) |> to_string()
  end

  def init(tick_time \\ 15000) do
    ip = Nodes.get_my_ip() |> ip_to_string()
    full_name = "heis" <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
    Node.set_cookie :hello


    spawn fn -> Beacon.start_link() end
    spawn fn -> Radar.start_link end
      #:timer.sleep(2000)

    spawn fn -> Nodes.start_link() end
    spawn fn -> Global_list.start_link end
  end
end
