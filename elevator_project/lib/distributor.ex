defmodule Distributor do
  @moduledoc """
  This is the distribitur module. The distributor is a part of the master, doing the computation
  of shortest-path and cost function, in order to distribute elevator orders. The distribitur in all
  nodes recieves the list of orders and states, but only the master distribitur distribute.
  """
  use GenServer
  @top 3
  @bottom 0

  # =========== GENSERVER =============
  # -------------API -----------------

  # create the genserver with an empty list
  def init do
    {:ok, _} = start()
  end

  def init(init_arg) do
      {:ok, init_arg}
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: :genserver)
  end

  def get_complete_list do
    GenServer.call(:genserver, :get_complete_list)
  end

  def find_elevator_in_complete_list(pid) do
    GenServer.call(:genserver, {:find_elevator_in_complete_list, pid})
  end

  def update_complete_list(new_elevator) do
    GenServer.cast(:genserver, {:update_complete_list, new_elevator})
  end

  def replace_elevator(new_elevator, pid) do
    GenServer.cast(:genserver, {:replace_elevator, new_elevator, pid})
  end

  def broadcast_complete_list_to_elevator(pid) do
    GenServer.cast(:genserver, {:broadcast_complete_list_to_elevator, pid})
  end

  # -------------CAST AND CALLS -----------------

  def handle_call(:get_complete_list, _from, complete_list) do
    {:reply, complete_list, complete_list}
  end

  def handle_call({:find_elevator_in_complete_list, pid}, _from, complete_list) do
    {:reply, CompleteSystem.elevator_by_key(:find_pid, complete_list, pid), complete_list}
  end

  def handle_cast({:update_complete_list, new_elevator}, complete_list) do
    {:noreply, complete_list ++ new_elevator}
  end

  def handle_cast({:replace_elevator, new_elevator, pid}, complete_list) do
    {:noreply, CompleteSystem.elevator_by_key(:replace, complete_list, pid, new_elevator)}
  end

  def handle_cast({:broadcast_complete_list_to_elevator, pid}, complete_list) do
    tell(pid, complete_list)
    {:noreply, :ok}
  end

  # ============ MAILBOX ============

  def tell(receiver_pid, message) do
    # logging
    IO.puts("[#{inspect(self())}] Sending #{message} to #{inspect(receiver_pid)}")
    send(receiver_pid, {:ok, self(), message})
  end

  def listen do
    IO.puts("[#{inspect(self())}] is listening")

    receive do
      {:state, sender_pid, state} ->
        IO.puts("[#{inspect(self())}] Received {}from #{inspect(sender_pid)}")
        update_system_list(sender_pid, state)

      {:order, sender_pid, order} ->
        IO.puts("[#{inspect(self())}] Received #{order} from #{inspect(sender_pid)}")
        update_system_list(sender_pid, order)
    after
      1_000 ->
        "nothing received by distributor after 1 second"
    end

    listen()
  end

  # update state of elevator by pid
  def update_system_list(sender_pid, state = %State{}) do
    elevator = find_elevator_in_complete_list(sender_pid)
    %{elevator | state: state}
    replace_elevator(elevator, sender_pid)
    delete_orders_completed(sender_pid, state)
    broadcast_complete_list(get_complete_list())
  end

  # distribute order to elevator with minimum cost
  def update_system_list(sender_pid, order = %Order{}) do
    light = Light.init(order.type, order.floor, :on)

    elevator_min_cost =
      case order.type do
        :cab ->
          elevator = find_elevator_in_complete_list(sender_pid)
          lights = elevator.lights ++ [light]
          orders = elevator.orders ++ [order]
          Elevator.init(elevator.ip, elevator.pid, elevator.state, orders, lights)

        _ ->
          update_lights_list(:add, get_complete_list(), light)
          compute_min_cost_all_elevators(get_complete_list())
      end
    replace_elevator(elevator_min_cost, elevator_min_cost.pid)
    broadcast_complete_list(get_complete_list())
  end

  def update_lights_list(key, complete_list, light, index \\ 0) do
    elevator = complete_list[index]
    case {elevator, key} do
      {:nil, _} -> :ok
      {_, :add} ->
        elevator = Elevator.init(elevator.ip, elevator.pid, elevator.state, elevator.orders, elevator.lights ++ [light])
        replace_elevator(elevator, elevator.pid)
        update_lights_list(get_complete_list(), light, index + 1)
      {_, :delete} ->
        elevator = Elevator.init(elevator.ip, elevator.pid, elevator.state, elevator.orders, elevator.lights -- [light])
        replace_elevator(elevator, elevator.pid)
        update_lights_list(get_complete_list(), light, index + 1)
      end
  end

  # delete order if new state of elevator is the same floor and direction as existing order
  def delete_orders_completed(sender_pid, state, iterate \\ 0) do
    elevator = find_elevator_in_complete_list(sender_pid)
    orders = elevator.orders
    order = Enum.at(orders, iterate)

    if state.floor == order.floor and state.direction == :idle do
      %{elevator | orders: List.delete_at(orders, iterate)}
      replace_elevator(elevator, sender_pid)
    end

    if iterate < orders.length do
      delete_orders_completed(sender_pid, state, iterate + 1)
    end
  end

  def broadcast_complete_list(complete_list, index \\ 0) do
    elevator = Enum.at(complete_list, index)

    cond do
      elevator == nil ->
        :error

      true ->
        broadcast_complete_list_to_elevator(elevator.pid)
        broadcast_complete_list(complete_list, index + 1)
    end
  end

  # ============== COST COMPUTATION ===================

  @doc """
  this function converts the direction in atoms to an integer
  """
  def direction_to_integer(state) do
    case state.direction do
      :up -> 1
      :idle -> 0
      :down -> -1
      _ -> :error
    end
  end

  def direction_order_to_state(order) do
    case order.type do
      :cab -> :idle
      :hall_up -> :up
      :hall_down -> :down
    end
  end

  @doc """
  this function count the number of orders of a single elevator
  """
  def number_of_orders(orders) do
    length(orders)
  end

  @doc """
  this function computes number of floors between a state and an order
  """
  def distance_between_orders(state, order) do
    abs(state.floor - order.floor)
  end

  def is_same_floor_same_direction(state, order) do
    case {state.direction, order.type} do
      {:down, :hall_down} -> state.floor == order.floor
      {:up, :hall_up} -> state.floor == order.floor
      _ -> false
    end
  end

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

  # Use pipe operator to make prettier
  def compute_min_cost_all_elevators(complete_list) do
    cost_list = []

    cost_list =
      Enum.map(complete_list, fn elevator ->
        cost_list ++ compute_cost_all_orders(elevator.state, elevator.orders)
      end)

    min_cost = Enum.min(cost_list)
    index = Enum.find_index(cost_list, fn x -> x == min_cost end)
    Enum.at(complete_list, index)
  end
end
