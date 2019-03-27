defmodule Distributor do
  @moduledoc """
  This is the distribitur module. The distributor is a part of the master, doing the computation
  of shortest-path and cost function, in order to distribute elevator orders. The distribitur in all
  nodes recieves the list of orders and states, but only the master distribitur distribute.
  """
  use GenServer
  @bottom 0
  @top 3

  @doc """
  Input is a list of tuples with the ip and pid of each node in the cluster.
  Setup the genserver, create a list of elevators with the pid and ip in the input
  and broadcast this list to all nodes.
  """
  # =========== GENSERVER =============
  # -------------API -----------------

  # create the genserver with an empty list
  def start(list_tuple_ips_pids) do
    IO.puts("DIST start pid: #{inspect(self())}")
    {:ok, pid_genserver} = start()
    IO.puts("Pid genserver: #{inspect(pid_genserver)}")

    Enum.map(list_tuple_ips_pids, fn {ip, pid} -> Elevator.init(ip, pid) end)
    |> update_complete_list()

    get_complete_list()
    |> Enum.map(fn elevator -> tell(elevator.pid, get_complete_list()) end)

    listen()
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

  def add_to_complete_list(new_elevator) do
    GenServer.cast(:genserver, {:add_to_complete_list, new_elevator})
  end

  def update_complete_list(new_list) do
    GenServer.cast(:genserver, {:update_complete_list, new_list})
  end

  def replace_elevator_in_complete_list(new_elevator, pid) do
    GenServer.cast(:genserver, {:replace_elevator_in_complete_list, new_elevator, pid})
  end

  # -------------CAST AND CALLS -----------------

  def handle_call(:get_complete_list, _from, complete_list) do
    IO.puts("get_complete_list #{inspect(complete_list)}")
    {:reply, complete_list, complete_list}
  end

  def handle_call({:get_elevator_in_complete_list, pid}, _from, complete_list) do
    IO.puts("get_elevator_in_complete_list ")
    {:reply, Enum.find(complete_list, fn elevator -> elevator.pid == pid end), complete_list}
  end

  def handle_cast({:add_to_complete_list, new_elevator}, complete_list) do
    IO.puts("add_to_complete_list")
    {:noreply, complete_list ++ new_elevator}
  end

  def handle_cast({:update_complete_list, new_list}, _) do
    IO.puts("update_complete_list to #{inspect(new_list)}")
    {:noreply, new_list}
  end

  def handle_cast({:replace_elevator_in_complete_list, new_elevator, pid}, complete_list) do
    IO.puts("
    replace_elevator_in_complete_list #{inspect(complete_list)}
    ")
    index = Enum.find_index(complete_list, fn elevator -> elevator.pid == pid end)
    {:noreply, List.replace_at(complete_list, index, new_elevator)}
  end

  # ============ MAILBOX ============

  @doc """
  Send a mesage to the node with given pid
  """
  def tell(receiver_pid, message) do
    IO.puts("DIST #{inspect(self())} Sending to #{inspect(receiver_pid)}")
    send(receiver_pid, {:ok, self(), message})
  end

  @doc """
  Handle received messages from other nodes. Elevator modules send their states and orders to the master
  """
  def listen do
    receive do
      {:state, sender_pid, state} ->
        IO.puts(
          "DIST [#{inspect(self())}] Received the state #{inspect(state)} from #{
            inspect(sender_pid)
          }"
        )

        update_system_list(sender_pid, state)

      {:order, sender_pid, order} ->
        IO.puts("DIST [#{inspect(self())}] Received from #{inspect(sender_pid)}")
        update_system_list(sender_pid, order)

        {:complete_list, sender_pid, complete_list} ->
            IO.puts("DIST [#{inspect(self())}] Received from #{inspect(sender_pid)}")
            pdate_complete_list(complete_list)

        message ->
          IO.puts(
            "Error distributor module: unexpected message before initialization #{inspect(message)}"
          )


      :error ->
        :error
    after
      3_000 ->
        IO.puts("#{inspect(self())} did not receive after 3 second")
    end

    listen()
  end

  @doc """
  Update state of elevator by pid. When receiving the state from an elevator module, the state in the stored
  list is updated and completed orders are deleted. An order is completed if the new state of the elevator is
  at the same floor as an existing order and has stopped. The light is set to Off if it was turned on earlier,
  or added to the light orders if not.
  """
  def update_system_list(sender_pid, state = %State{}) do
    elevator = get_elevator_in_complete_list(sender_pid)

    %{elevator | state: state}
    |> replace_elevator_in_complete_list(sender_pid)

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

        %{elevator | orders: elevator.orders -- [order], lights: lights}
        |> replace_elevator_in_complete_list(sender_pid)
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
  def update_system_list(sender_pid, order = %Order{}) do
    new_light = Light.init(order.type, order.floor, :on)
    IO.puts("Light on created")

    elevator_min_cost =
      case order.type do
        :cab ->
          elevator = get_elevator_in_complete_list(sender_pid)

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
          Enum.map(get_complete_list(), fn elevator ->
            if Enum.any?(elevator.lights, fn light -> light != new_light end) or
                 elevator.lights == [] do
              IO.puts("_____add light to list #{inspect(new_light)}")
              %{elevator | lights: elevator.lights ++ [new_light]}
            else
              IO.puts("_____light already in list #{inspect(new_light)}")
              elevator
            end
          end)
          |> update_complete_list()

          elevator_min = compute_min_cost_all_elevators(get_complete_list())
          %{elevator_min | orders: elevator_min.orders ++ [order]}
      end

    replace_elevator_in_complete_list(elevator_min_cost, elevator_min_cost.pid)
    Enum.map(get_complete_list(), fn elevator -> tell(elevator.pid, get_complete_list()) end)
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
  Computes number of floors between a state and an order
  """
  def distance_between_orders(state, order) do
    abs(state.floor - order.floor)
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
        distance_between_orders(state, order)

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
