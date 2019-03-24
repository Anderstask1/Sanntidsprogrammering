defmodule Distributor do
  @moduledoc """
  This is the distribitur module. The distributor is a part of the master, doing the computation
  of shortest-path and cost function, in order to distribute elevator orders. The distribitur in all
  nodes recieves the list of orders and states, but only the master distribitur distribute.
  """
  use GenServer
  @top 3
  @bottom 0

  #=========== GENSERVER =============
  #-------------API -----------------

  def init do #create the genserver with an empty list
    {:ok, _} = start()
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: :genserver)
  end

  def get_complete_list do
      GenServer.call(:genserver, :get_complete_list)
  end

  def update_complete_list(new_elevator) do
    GenServer.cast(:genserver, {:update_complete_list, new_elevator})
  end

  def find_elevator_in_complete_list() do

  end

  def replace_elevator(new_elevator, sender_pid) do
      GenServer.cast(:genserver, {:replace_elevator, new_elevator, sender_pid})
  end

  #-------------CAST AND CALLS -----------------

  def handle_call(:get_complete_list, _from, complete_list) do
    {:reply, complete_list, complete_list}
  end

  def handle_cast({:update_complete_list, new_elevator}, complete_list) do
    {:noreply, complete_list ++ new_elevator}
  end

  def handle_cast({:replace_elevator, new_elevator, sender_pid}, complete_list) do
    {:noreply, CompleteSystem.elevator_by_pid(:replace, complete_list, sender_pid, new_elevator)}
  end

  #============ MAILBOX ============

  def tell(receiver_pid, message) do
    IO.puts "[#{inspect self()}] Sending #{message} to #{inspect receiver_pid}" #logging
    send receiver_pid, {:ok, self(), message}
  end

  def listen do
    IO.puts "[#{inspect self()}] is listening"
    receive do
      {:state, sender_pid, state} ->
        IO.puts "[#{inspect self()}] Received #{state} from #{inspect sender_pid}"
        update_system_list(sender_pid, state)
      {:order, sender_pid, order} ->
        IO.puts "[#{inspect self()}] Received #{order} from #{inspect sender_pid}"
        update_system_list(sender_pid, order)
    end
    listen()
  end

  def update_system_list(sender_pid, state = %State{}) do #update state of elevator by pid
    elevator = CompleteSystem.elevator_by_pid(:find, get_complete_list(), sender_pid)
    %{elevator | state: state}
    complete_system = CompleteSystem.elevator_by_pid(:replace, get_complete_list(), sender_pid, elevator)
    update_orders_completed(sender_pid, state)
  end

  def update_system_list(sender_pid, order = %Order{}) do #distribute order to elevator with minimum cost, now it just add order to same elevator
    elevator_min_cost = compute_min_cost_all_elevators(get_complete_list())
    orders = elevator_min_cost.orders ++ [order]
    CompleteSystem.elevator_by_pid(:replace, get_complete_list(), sender_pid, elevator_min_cost)
  end

  def update_orders_completed(sender_pid, state, iterate \\ 0) do #check if new state of elevator is the same floor and direction as existing order
    elevator = CompleteSystem.elevator_by_pid(:find, get_complete_list(), sender_pid)
    orders = elevator.orders
    order = Enum.at(orders, iterate)
    if is_same_floor_same_direction(state, order) do
      %{elevator | orders: List.delete_at(orders, iterate)}
      CompleteSystem.elevator_by_pid(:replace, get_complete_list(), sender_pid, elevator)
    end
    if iterate < orders.length do
      update_orders_completed(sender_pid, state, iterate + 1)
    end
  end

  #============== COST COMPUTATION ===================

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
          #state.floor == @top -> duration
          #state.floor == @bottom -> duration
          is_same_floor_same_direction(state, order) -> duration
          true ->
            state =
              case {state.direction, state.floor} do
                  {:up, @top} -> %State{state | direction: :down}
                  {:down, @bottom} -> %State{state | direction: :up}
                  _ -> %State{state | floor: (state.floor + direction_to_integer(state))}
              end
            simulate_elevator(duration+1, state, order)
      end
  end

  @doc """
  this function compute the cost for a single elevator. the order
  """
  def compute_cost_order(state, order) do
    case {state.direction, order.type} do
        {:idle, _} -> distance_between_orders(state, order)
        {_, :cab} -> distance_between_orders(state, order)
        _other ->
          simulate_elevator(0, state, order)
    end
  end

  def compute_cost_all_orders(state, orders) do
      cost_list = []
      orders |>
      Enum.map(fn order ->  %Order{order | cost: order.cost + compute_cost_order(state, order)} end) |>
      Enum.map(fn order -> cost_list ++ order.cost end) |>
      Enum.sum()
  end

  def compute_min_cost_all_elevators(complete_list) do
      cost_list = []
      cost_list = Enum.map(complete_list, fn elevator -> cost_list ++ compute_cost_all_orders(elevator.state, elevator.orders) end)
      min_cost = Enum.min(cost_list)
      index = Enum.find_index(cost_list, fn x -> x == min_cost end)
      Enum.at(complete_list,index)
  end
end
