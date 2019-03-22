defmodule Init do

  @moduledoc """
  This is the init module. The init module is setting up the system, doing the necessary initial
  config. This includes udp-broadcast to set up the cluster, spawning the modules and sending an empty
  list to all elevators.
  """
  def ip_to_string ip do
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

  def init(node_name, tick_time \\ 15000) do
    ip = get_my_ip() |> ip_to_string()
    full_name = node_name <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
    Node.set_cookie :hallo
  end
end
