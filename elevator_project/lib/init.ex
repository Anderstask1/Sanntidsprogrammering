defmodule Init do

  @moduledoc """
  This is the init module. The init module is setting up the system, doing the necessary initial
  config. This includes udp-broadcast to set up the cluster, spawning the modules and sending an empty
  list to all elevators.
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

  @doc """
  initializes a node. Gives it a name and makes it search for other nodes while
  it broadcasts itself.
  """
  def init(tick_time \\ 15000) do
    ip = get_my_ip() |> ip_to_string()
    full_name = "heis" <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
    Node.set_cookie :hello
    spawn fn -> List_name_pid.init end
    spawn fn -> Beacon.start_link end
    spawn fn -> Radar.start_link end
  end
end
