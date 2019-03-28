defmodule Distributor do
  @moduledoc """
  The distributor is a part of the master, doing the computation of shortest-path and cost function,
  in order to distribute elevator orders. The distribitur in all nodes recieves the list of orders
  and states, but only the master distribitur distribute.
  """
  use GenServer
  @bottom 0
  @top 3

  @doc """
  Input is a list of tuples with the ip of each node in the cluster.
  Setup the genserver, create a list of elevators with the ip in the input
  and broadcast this list to all nodes.
  """

  # create the genserver with an empty list
  def start() do
    IO.puts("DIST start pid: #{inspect(self())}")
    {:ok, pid_genserver} = start_server()
    IO.puts("Pid genserver: #{inspect(pid_genserver)}")
    Enum.map(Nodes.get_list(), fn ip -> Elevator.init(ip) end)
    |> update_complete_list()
    |> multi_call_reply_handling()

    {:ok, ip_watchdog} = WatchdogList.start()
    IO.puts("ip watchdog: #{inspect(ip_watchdog)}")
    Enum.map(Nodes.get_list(), fn ip -> WatchdogList.add_to_watchdog_list(ip) end)
  end

  # =========== GENSERVER =============
  # -------------API -----------------

  def init(list) do
    {:ok, list}
  end

  def start_server do
    GenServer.start_link(__MODULE__, [], name: :genserver)
  end

  def get_complete_list do
    GenServer.call(:genserver, :get_complete_list)
  end

  def get_elevator_in_complete_list(ip) do
    GenServer.call(:genserver, {:get_elevator_in_complete_list, ip})
  end

  def send_order(order) do
    GenServer.multi_call(Nodes.get_list(), :genserver, {:send_order, order})
  end

  def send_state(state) do
    GenServer.multi_call(Nodes.get_list(), :genserver, {:send_state, state})
  end

  def send_backup(backup) do
    GenServer.multi_call(Nodes.get_list(), :genserver, {:send_backup, backup})
  end

  def add_to_complete_list(new_elevator) do
    if Observer.is_master(Nodes.get_my_ip()) do
      GenServer.multi_call(Nodes.get_list(), :genserver, {:add_to_complete_list, new_elevator})
    end
  end

  def update_complete_list(new_list) do
    if Observer.is_master(Nodes.get_my_ip()) do
      GenServer.multi_call(Nodes.get_list(), :genserver, {:update_complete_list, new_list})
    end
  end

  def replace_elevator_in_complete_list(new_elevator, ip) do
    if Observer.is_master(Nodes.get_my_ip()) do
      GenServer.multi_call(Nodes.get_list(), :genserver, {:replace_elevator_in_complete_list, new_elevator, ip})
    end
  end

  def delete_elevator_in_complete_list(elevator) do
    if Observer.is_master(Nodes.get_my_ip()) do
      GenServer.multi_call(Nodes.get_list(), :genserver, {:delete_elevator_in_complete_list, elevator})
    end
  end

  # -------------CAST AND CALLS -----------------

  def handle_call(:get_complete_list, _from, complete_list) do
    IO.puts("get_complete_list")
    {:reply, complete_list, complete_list}
  end

  def handle_call({:get_elevator_in_complete_list, ip}, _from, complete_list) do
    IO.puts("get_elevator_in_complete_list ")
    {:reply, Enum.find(complete_list, fn elevator -> elevator.ip == ip end), complete_list}
  end

  def handle_call({:send_order, order}, from, complete_list) do
    IO.puts(
      "DIST [#{inspect(self())}] Received the order #{inspect(order)} from #{inspect(from)}"
    )

    kill_broken_elevators()

    elem(from, 1)
    |> elem(1)
    |> update_system_list(order)

    {:reply, complete_list, complete_list}
  end

  def handle_call({:send_state, state}, from, complete_list) do
    IO.puts(
      "DIST [#{inspect(self())}] Received the state #{inspect(state)} from #{inspect(from)}"
    )

    kill_broken_elevators()

    elem(from, 1)
    |> elem(1)
    |> update_system_list(state)

    {:reply, complete_list, complete_list}
  end

  def handle_call({:send_backup, elevator_backup}, from, complete_list) do
    IO.puts(
      "DIST [#{inspect(self())}] Received the backup #{inspect(elevator_backup)} from #{
        inspect(from)
      }"
    )

    from_ip = elem(elem(from, 1), 1)
    Enum.map(elevator_backup.orders, fn order -> update_system_list(from_ip, order) end)
    update_system_list(from_ip, elevator_backup.state)
    update_system_list(from_ip, elevator_backup.lights)
    {:reply, complete_list, complete_list}
  end

  def handle_call({:add_to_complete_list, new_elevator}, complete_list) do
    IO.puts("DIST [#{inspect(self())}] add_to_complete_list")
    {:noreply, complete_list ++ new_elevator}
  end

  def handle_call({:update_complete_list, new_list}, _) do
    IO.puts("DIST [#{inspect(self())}] update_complete_list to")
    {:noreply, new_list}
  end

  def handle_call({:replace_elevator_in_complete_list, new_elevator, ip}, complete_list) do
    IO.puts("DIST [#{inspect(self())}] replace_elevator_in_complete_list")
    index = Enum.find_index(complete_list, fn elevator -> elevator.ip == ip end)
    {:noreply, List.replace_at(complete_list, index, new_elevator)}
  end

  def handle_call({:delete_elevator_in_complete_list, elevator}, complete_list) do
    IO.puts("DIST [#{inspect(self())}] delete_elevator_in_complete_list")
    {:noreply, List.delete(complete_list, elevator)}
  end

  # ============ MAILBOX ============

  def multi_call_reply_handling(reply) when reply != nil do
    elem(reply, 1) |>
    Enum.each(fn bad_node ->
      broken_elevator = get_elevator_in_complete_list(NodeCollector.ip(bad_node))
      delete_elevator_in_complete_list(broken_elevator)
      |> multi_call_reply_handling()
      redistribute_orders(broken_elevator)
    end)
end

###### ================== CHANGE THIS TO IP
def kill_broken_elevators do
  case WatchdogList.is_elevator_broken() do
    nil ->
      IO.puts("No elevator to kill")

    {ip, _, _} ->
      IO.puts("kill node #{inspect(ip)}")
      broken_elevator = get_elevator_in_complete_list(ip)
      %{broken_elevator | harakiri: true}
      |> replace_elevator_in_complete_list(ip) # Hakiri: Japanese= cut your belly
      |> multi_call_reply_handling()

      if length(get_complete_list()) == 1 do
        IO.puts("Master say goodbye ;( ")
        Process.exit(self(), :kill)
      end

      delete_elevator_in_complete_list(broken_elevator)
      |> multi_call_reply_handling()
      redistribute_orders(broken_elevator)
    end
  end

  def redistribute_orders(elevator) do
    Enum.each(elevator.orders, fn order ->
      if order != :cab do
        update_system_list(elevator.ip, order)
      end
    end)
  end


  @doc """
  Update state of elevator by ip. When receiving the state from an elevator module, the state in the stored
  list is updated and completed orders are deleted. An order is completed if the new state of the elevator is
  at the same floor as an existing order and has stopped. The light is set to Off if it was turned on earlier,
  or added to the light orders if not. The watchdog check if an elevator is using too long time to move between
  floors, and kill the node if that is the case
  """
  def update_system_list(sender_ip, state = %State{}) do
    elevator = get_elevator_in_complete_list(sender_ip)
    # if elevator.orders != [] do
    #   IO.puts("Elevator has orders, update time")
    #   WatchdogList.update_watchdog_list(elevator.ip)
    # end
    %{elevator | state: state}
    |> replace_elevator_in_complete_list(sender_ip)
    |> multi_call_reply_handling()

    Enum.map(elevator.orders, fn order ->
      if state.floor == order.floor and state.direction == :idle do
        lights =
          Enum.map(elevator.lights, fn light ->
            if light.floor == order.floor do
              %Light{light | state: :off}
            else
              light
            end
          end)

        new_elevator = %{elevator | orders: elevator.orders -- [order], lights: lights}
        replace_elevator_in_complete_list(new_elevator, sender_ip)
        |> multi_call_reply_handling()

        IO.puts(
          "DISTRIBUTOR -> Order completed, updating watchdog times if there is still orders"
        )

        if new_elevator.orders != [] do
          IO.puts("Orders exist: update watchdog time")
          WatchdogList.update_watchdog_list(elevator.ip)
        end
      end
    end)
  end

  @doc """
  Update orders and lights of elevators. When receiving an order from an elevator module, the order is
  distributed to the elevator with minimum cost and added to the bottom of the orders list. Lights is
  set to be turned on when an orders is distributed, eighter by changing the same light order to Off
  or adding it to light order list.
  """
  def update_system_list(sender_ip, order = %Order{}) do
    elevator =
      if get_elevator_in_complete_list(sender_ip) == nil do
        Elevator.init([])
      else
        get_elevator_in_complete_list(sender_ip)
      end

    new_light = Light.init(order.type, order.floor, :on)
    IO.puts("Light on created")

    elevator_min_cost =
      case order.type do
        :cab ->
          if Enum.any?(elevator.lights, fn light -> light != new_light end) or
               elevator.lights == [] do
            IO.puts("______CAB add light to list #{inspect(new_light)}")

            %{
              elevator
              | orders: elevator.orders ++ [order],
                lights: elevator.lights ++ [new_light]
            }
          else
            IO.puts("______CAB light already in list #{inspect(new_light)}")
            %{elevator | orders: elevator.orders ++ [order]}
          end

        _ ->
          Enum.map(get_complete_list(), fn elevator_in_list ->
            if Enum.any?(elevator_in_list.lights, fn light -> light != new_light end) or
                 elevator_in_list.lights == [] do
              IO.puts("_____add light to list #{inspect(new_light)}")
              %{elevator_in_list | lights: elevator_in_list.lights ++ [new_light]}
            else
              IO.puts("_____light already in list #{inspect(new_light)}")
              elevator_in_list
            end
          end)
          |> update_complete_list()
          |> multi_call_reply_handling()
          elevator_min = compute_min_cost_all_elevators(get_complete_list())
          WatchdogList.update_watchdog_list(elevator_min.ip)
          %{elevator_min | orders: elevator_min.orders ++ [order]}
      end

    replace_elevator_in_complete_list(elevator_min_cost, elevator_min_cost.ip)
    |> multi_call_reply_handling()
  end

  @doc """
  Replace
  """
  def update_system_list(sender_ip, lights) do
    elevator = get_elevator_in_complete_list(sender_ip)

    %{elevator | lights: lights}
    |> replace_elevator_in_complete_list(sender_ip)
    |> multi_call_reply_handling()
  end

  # ============== COST COMPUTATION ===================

  @doc """
  Converts the direction in atoms to an integer
  """
  def direction_to_integer(state) do
    case state.direction do
      :up -> 1
      :idle -> 0
      :down -> -1
      _ -> :error
    end
  end

  @doc """
  Check if the state of the elevator and an order is at the same floor and
  moving in the same direction
  """
  def is_same_floor_same_direction(state, order) do
    case {state.direction, order.type} do
      {:down, :hall_down} -> state.floor == order.floor
      {:up, :hall_up} -> state.floor == order.floor
      _ -> false
    end
  end

  @doc """
  Simulate an elevator, computing number of steps from the state of the elevator to
  the order. Fulfilled when state and order is the same floor and direction
  """
  def simulate_elevator(duration, state, order) do
    cond do
      is_same_floor_same_direction(state, order) ->
        duration
      true ->
        state =
          case {state.direction, state.floor} do
            {:up, @top} -> %State{state | direction: :down}
            {:down, @bottom} -> %State{state | direction: :up}
            _ -> %State{state | floor: state.floor + direction_to_integer(state)}
          end
        simulate_elevator(duration + 1, state, order)
    end
  end

  @doc """
  this function compute the cost for a single elevator. the order
  """
  def compute_cost_order(state, order) do
    case {state.direction, order.type} do
      {:idle, _} ->
        abs(state.floor - order.floor)

      _other ->
        simulate_elevator(0, state, order)
    end
  end

  def compute_cost_all_orders(state, orders) do
    cost_list = []
    orders
    |> Enum.map(fn order ->
      %Order{order | cost: order.cost + compute_cost_order(state, order)}
    end)
    |> Enum.map(fn order -> cost_list ++ order.cost end)
    |> Enum.sum()
  end

  def compute_min_cost_all_elevators(complete_list) do
    cost_list =
      Enum.map(complete_list, fn elevator ->
        compute_cost_all_orders(elevator.state, elevator.orders)
      end)

    min_cost = Enum.min(cost_list)
    index = Enum.find_index(cost_list, fn x -> x == min_cost end)
    Enum.at(complete_list, index)
  end
end

defmodule WatchdogList do
  @moduledoc """
  The watchdog is watching all elevators, checking if an elevator is using more than 5 seconds to move bewteen floors.
  """
  use GenServer

  # =========== GENSERVER =============
  # -------------API -----------------

  def init(list) do
    {:ok, list}
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: :watchdoglist)
  end

  def get_watchdog_list(ip) do
    GenServer.call(:watchdoglist, {:get_watchdog_list, ip})
  end

  def is_elevator_broken do
    GenServer.call(:watchdoglist, {:is_elevator_broken, Time.utc_now()})
  end

  def add_to_watchdog_list(ip) do
    GenServer.cast(:watchdoglist, {:add_to_watchdog_list, ip})
  end

  def update_watchdog_list(ip) do
    GenServer.cast(:watchdoglist, {:update_watchdog_list, ip})
  end

  # -------------CAST AND CALLS -----------------

  def handle_call({:get_watchdog_list, find_ip}, _from, watchdog_list) do
    IO.puts("Get watchdog list #{inspect(watchdog_list)} with ip #{inspect(find_ip)}")

    {:reply, Enum.find(watchdog_list, fn {ip, _} -> ip == find_ip end),
     watchdog_list}
  end

  def handle_call({:is_elevator_broken, new_time}, _from, watchdog_list) do
    IO.puts("Check if elevator is broken")

    Enum.each(watchdog_list, fn {_, _, time} ->
      IO.puts("new time: #{inspect(new_time)} and old time: #{inspect(time)}")
    end)

    {:reply,
     Enum.find(watchdog_list, fn {_, _, time} ->
       !(time == nil or Time.diff(new_time, time) < 25)
     end), watchdog_list}
  end

  def handle_cast({:add_to_watchdog_list, ip}, watchdog_list) do
    IO.puts("Add time to ip #{inspect(ip)} in watchdog_list #{inspect(watchdog_list)}")
    {:noreply, watchdog_list ++ [{ip, nil}]}
  end

  def handle_cast({:update_watchdog_list, find_ip}, watchdog_list) do
    IO.puts(
      "Update time in watchdog with ip #{inspect(find_ip)} in watchdog_list #{
        inspect(watchdog_list)
      }"
    )

    watchdog =
      Enum.map(watchdog_list, fn {ip, time} ->
        if ip == find_ip do
          {find_ip, Time.utc_now()}
        else
          {ip, time}
        end
      end)

    {:noreply, watchdog}
  end
end
