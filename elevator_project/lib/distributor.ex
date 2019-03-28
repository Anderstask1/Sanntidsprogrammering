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
  Input is a list of tuples with the ip and pid of each node in the cluster.
  Setup the genserver, create a list of elevators with the pid and ip in the input
  and broadcast this list to all nodes.
  """

  # create the genserver with an empty list
  def start(list_tuple_ips_pids) do
    IO.puts("DIST start pid: #{inspect self()}")
    {:ok, pid_genserver} = start()
    IO.puts("Pid genserver: #{inspect pid_genserver}")
    Enum.map(list_tuple_ips_pids, fn {ip, pid} -> Elevator.init(ip, pid) end) |>
    update_complete_list()
    {:ok, pid_watchdog} = WatchdogList.start()
    IO.puts("Pid watchdog: #{inspect pid_watchdog}")
    Enum.map(list_tuple_ips_pids, fn {ip, pid} -> WatchdogList.add_to_watchdog_list(ip, pid) end)
    get_complete_list() |>
    Enum.map(fn elevator -> tell(elevator.pid, get_complete_list()) end)
  end

  # =========== GENSERVER =============
  # -------------API -----------------

  def init(list) do
    {:ok, list}
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: :genserver)
  end

  def get_complete_list do
    GenServer.call(:genserver, :get_complete_list)
  end

  def get_elevator_in_complete_list(pid) do
    GenServer.call(:genserver, {:get_elevator_in_complete_list, pid})
  end

  def send_order(order) do
      Genserver.multi_call(Nodes.get_list(), :genserver, {:send_order, order})
  end

  def send_state(state) do
      Genserver.multi_call(Nodes.get_list(), :genserver, {:send_state, state})
  end

  def send_backup(backup) do
      Genserver.multi_call(Nodes.get_list(), :genserver, {:send_backup, backup})
  end

  def add_to_complete_list(new_elevator) do
    GenServer.cast(:genserver, {:add_to_complete_list, new_elevator})
  end

  def update_complete_list(new_list) do
    GenServer.cast(:genserver, {:update_complete_list, new_list})
  end

  def replace_elevator_in_complete_list(new_elevator, pid) do
    GenServer.cast(:genserver, {:replace_elevator_in_complete_list, new_elevator, pid})
  end

  def delete_elevator_in_complete_list(elevator) do
    GenServer.cast(:genserver, {:delete_elevator_in_complete_list, elevator})
  end

  # -------------CAST AND CALLS -----------------

  def handle_call(:get_complete_list, _from, complete_list) do
    IO.puts("get_complete_list")
    {:reply, complete_list, complete_list}
  end

  def handle_call({:get_elevator_in_complete_list, id}, _from, complete_list) do
    IO.puts("get_elevator_in_complete_list ")
    {:reply, Enum.find(complete_list, fn elevator -> elevator.id == id end), complete_list}
  end

  def handle_call({:send_order, order}, from_pid, complete_list) do
      IO.puts("DIST [#{inspect(self())}] Received the order #{inspect order} from #{inspect(from_pid)}")
      kill_broken_elevators()
      update_system_list(get_elevator_in_complete_list(from_pid), order)
      {:reply, complete_list, complete_list}
  end

  def handle_call({:send_state, state}, from_pid, complete_list) do
      IO.puts("DIST [#{inspect(self())}] Received the state #{inspect state} from #{inspect(from_pid)}")
      kill_broken_elevators()
      update_system_list(from_pid, state)
      {:reply, complete_list, complete_list}
  end

  def handle_call({:send_backup, elevator_backup}, from_pid, complete_list) do
      IO.puts("DIST [#{inspect(self())}] Received the backup #{inspect elevator_backup} from #{inspect(from_pid)}")
      Enum.map(elevator_backup.orders, fn order -> update_system_list(get_elevator_in_complete_list(from_pid), order) end)
      update_system_list(from_pid, elevator_backup.state)
      update_system_list(from_pid, elevator_backup.lights)
      {:reply, complete_list, complete_list}
  end

  def handle_cast({:add_to_complete_list, new_elevator}, complete_list) do
    IO.puts("add_to_complete_list")
    {:noreply, complete_list ++ new_elevator}
  end

  def handle_cast({:update_complete_list, new_list}, _) do
    IO.puts("update_complete_list to")
    {:noreply, new_list}
  end

  def handle_cast({:replace_elevator_in_complete_list, new_elevator, pid}, complete_list) do
    IO.puts("replace_elevator_in_complete_list")
    index = Enum.find_index(complete_list, fn elevator -> elevator.pid == pid end)
    {:noreply, List.replace_at(complete_list, index, new_elevator)}
  end

  def handle_cast({:delete_elevator_in_complete_list, elevator}, complete_list) do
    IO.puts("delete_elevator_in_complete_list")
    {:noreply, List.delete(complete_list, elevator)}
  end

  # ============ MAILBOX ============

  @doc """
  Send a mesage to the node with given pid
  """
  def tell(receiver_pid, message) do
    IO.puts("DIST #{inspect self()} Sending to #{inspect receiver_pid}")
    send(receiver_pid, {:ok, self(), message})
  end

  def listen do
      receive do
          {:bad_nodes, _, bad_nodes} ->
              Enum.each(bad_nodes, fn bad_node ->
                  NodeCollector.ip(bad_node) |>
                  get_elevator_in_complete_list() |>
                  redistribute_orders()
              end)
          message ->
            IO.puts("Error distributor module: unexpected message #{inspect(message)}")
      end
      listen()
  end

  def kill_broken_elevators do
    case WatchdogList.is_elevator_broken() do
      nil -> IO.puts"No elevator to kill"
      {_ip, pid, _} ->
        IO.puts "kill node #{inspect pid}"
        tell(pid, :harakiri) # Japanese: cut your belly
        if length(get_complete_list()) == 1 do
            IO.puts "Master say goodbye ;( "
            Process.exit(self(), :kill)
        end
        killed_elevator = get_elevator_in_complete_list(pid)
        delete_elevator_in_complete_list(killed_elevator)
        redistribute_orders(killed_elevator)
      end
  end

  def redistribute_orders(elevator) do
      Enum.each(elevator.orders, fn order ->
          if order != :cab do
              update_system_list(Elevator.init([], []), order)
          end
      end)
  end

  @doc """
  Update state of elevator by pid. When receiving the state from an elevator module, the state in the stored
  list is updated and completed orders are deleted. An order is completed if the new state of the elevator is
  at the same floor as an existing order and has stopped. The light is set to Off if it was turned on earlier,
  or added to the light orders if not. The watchdog check if an elevator is using too long time to move between
  floors, and kill the node if that is the case
  """
  def update_system_list(sender_pid, state = %State{}) do
    elevator = get_elevator_in_complete_list(sender_pid)
    # if elevator.orders != [] do
    #   IO.puts("Elevator has orders, update time")
    #   WatchdogList.update_watchdog_list(elevator.ip, elevator.pid)
    # end
    %{elevator | state: state}
    |> replace_elevator_in_complete_list(sender_pid)
    Enum.map(elevator.orders, fn order ->
      if state.floor == order.floor and state.direction == :idle do
        lights = Enum.map(elevator.lights, fn light ->
          if light.floor == order.floor do
            %Light{light | state: :off}
          else
            light
          end
        end)
        new_elevator = %{elevator | orders: elevator.orders -- [order], lights: lights}
        replace_elevator_in_complete_list(new_elevator, sender_pid)
        IO.puts "DISTRIBUTOR -> Order completed, updating watchdog times if there is still orders"
        if new_elevator.orders != [] do
            IO.puts("Orders exist: update watchdog time")
            WatchdogList.update_watchdog_list(elevator.ip, elevator.pid)
        end
      end
    end)
    Enum.map(get_complete_list(), fn elevator -> tell(elevator.pid, get_complete_list()) end)
  end

  @doc """
  Update orders and lights of elevators. When receiving an order from an elevator module, the order is
  distributed to the elevator with minimum cost and added to the bottom of the orders list. Lights is
  set to be turned on when an orders is distributed, eighter by changing the same light order to Off
  or adding it to light order list.
  """
  def update_system_list(elevator, order = %Order{}) do
    new_light = Light.init(order.type, order.floor, :on)
    IO.puts "Light on created"
    elevator_min_cost =
      case order.type do
        :cab ->
          if Enum.any?(elevator.lights, fn light -> light != new_light end) or elevator.lights == [] do
            IO.puts("______CAB add light to list #{inspect new_light}")
            %{elevator | orders: elevator.orders ++ [order], lights: elevator.lights ++ [new_light]}
          else
            IO.puts("______CAB light already in list #{inspect new_light}")
            %{elevator | orders: elevator.orders ++ [order]}
          end
        _ ->
          Enum.map(get_complete_list(), fn elevator_in_list ->
            if Enum.any?(elevator_in_list.lights, fn light -> light != new_light end) or elevator_in_list.lights == [] do
              IO.puts("_____add light to list #{inspect new_light}")
              %{elevator_in_list |lights: elevator_in_list.lights ++ [new_light]}
            else
              IO.puts("_____light already in list #{inspect new_light}")
              elevator_in_list
            end
          end) |>
          update_complete_list()
          elevator_min = compute_min_cost_all_elevators(get_complete_list())
          WatchdogList.update_watchdog_list(elevator_min.ip, elevator_min.pid)
          %{elevator_min | orders: elevator_min.orders ++ [order]}
      end

    replace_elevator_in_complete_list(elevator_min_cost, elevator_min_cost.pid)
    Enum.map(get_complete_list(), fn elevator -> tell(elevator.pid, get_complete_list()) end)
  end

  @doc """
  Replace
  """
  def update_system_list(sender_pid, lights) do
    elevator = get_elevator_in_complete_list(sender_pid)
    %{elevator | lights: lights} |>
    replace_elevator_in_complete_list(sender_pid)
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
      Enum.map(complete_list, fn elevator -> compute_cost_all_orders(elevator.state, elevator.orders) end)

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

  def get_watchdog_list(ip, pid) do
    GenServer.call(:watchdoglist, {:get_watchdog_list, ip, pid})
  end

  def is_elevator_broken do
    GenServer.call(:watchdoglist, {:is_elevator_broken, Time.utc_now})
  end

  def add_to_watchdog_list(ip, pid) do
    GenServer.cast(:watchdoglist, {:add_to_watchdog_list, ip, pid})
  end

  def update_watchdog_list(ip, pid) do
    GenServer.cast(:watchdoglist, {:update_watchdog_list, ip, pid})
  end

  # -------------CAST AND CALLS -----------------

  def handle_call({:get_watchdog_list, find_ip, find_pid}, _from, watchdog_list) do
    IO.puts("Get watchdog list #{inspect watchdog_list} with pid #{inspect find_pid}")
    {:reply, Enum.find(watchdog_list, fn {ip, pid, _} -> ip == find_ip and pid == find_pid end), watchdog_list}
  end

  def handle_call({:is_elevator_broken, new_time}, _from, watchdog_list) do
    IO.puts("Check if elevator is broken")
    Enum.each(watchdog_list, fn {_, _, time} -> IO.puts("new time: #{inspect new_time} and old time: #{inspect time}") end)
    {:reply, Enum.find(watchdog_list, fn {_, _, time} -> !(time == nil or Time.diff(new_time, time) < 25) end), watchdog_list}
  end

  def handle_cast( {:add_to_watchdog_list, ip, pid}, watchdog_list) do
    IO.puts("Add time to pid #{inspect pid} in watchdog_list #{inspect watchdog_list}")
    {:noreply, watchdog_list ++ [{ip, pid, nil}]}
  end

  def handle_cast({:update_watchdog_list, find_ip, find_pid}, watchdog_list) do
    IO.puts("Update time in watchdog with pid #{inspect find_pid} in watchdog_list #{inspect watchdog_list}")
    watchdog = Enum.map(watchdog_list, fn {ip, pid, time} ->
      if ip == find_ip and pid == find_pid do
        {find_ip, find_pid, Time.utc_now}
      else
        {ip, pid, time}
      end
    end)
    {:noreply, watchdog}
  end

end
