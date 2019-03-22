defmodule Distributor do

  @moduledoc """
  This is the distribitur module. The distributor is a part of the master, doing the computation
  of shortest-path and cost function, in order to distribute elevator orders. The distribitur in all
  nodes recieves the list of orders and states, but only the master distribitur distribute.
  INPUT:
        -list from each elevator
            - state
            - orders
            - lights
  OUTPUT:
        - complete list of orders and lights
            - added shortest path orders to list
            - added lights to list
  """

  @top 3
  @bottom 0

  @doc """
  this function says hello
  """
  def hello do
    IO.puts "Hello brothers and sisters"
  end

  def tell(receiver_pid, message) do
    IO.puts "[#{inspect self()}] Sending #{message} to #{inspect receiver_pid}"
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

  def update_system_list(sender_pid, state = %State{}) do
    elevator = CompleteSystem.find_elevator_by_pid(complete_list, sender_pid)
    %{elevator | state: state}
    
    update_orders_completed(sender_pid, state)
  end

  def update_system_list(sender_pid, order = %Order{}) do
    :elevator_old = CompleteSystem.find_elevator_by_pid(complete_list, sender_pid)
    %{elevator_old | orders: elevator_old.orders ++ order}
  end

  def update_orders_completed(sender_pid, state, iterate \\ 0) do
    elevator = CompleteSystem.find_elevator_by_pid(complete_list, sender_pid)
    orders = elevator.orders
    order = Enum.at(orders, iterate)
    if is_same_floor_same_direction(state, order) do
      %{elevator | orders: List.delete_at(orders, iterate)}
    end
    if iterate < orders.length do
      update_orders_completed(sender_pid, state, iterate + 1)
    end
  end

  @doc """
  this function converts the direction in atoms to an integer
  INPUT:
    - touple with state of elevator, containing direction and floor (unused)
  OUTPUT:
    - integer where up = 1, down = -1 and idle = 0
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
  this function count the number of orders of a single elevator
  INPUT:
    - orders of the elevator
  OUTPUT:
    - number of orders
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
  this function compute the cost for a single elevator.
  INPUT:
    - state and orders of a single elevator, and the new order
  OUTPUT:
    - the cost of taking the order for that elevator, a higher number indicates a high cost for taking the order
  """
  def compute_cost_order(state, order) do
      #first_order_floor = Enum.fetch(orders, 0) # extract first element of list
      #weight_nr_orders = 10
      #weight_distance_orders = 1
      #number_of_orders(orders)*weight_nr_orders + distance_between_orders(state, new_order)*weight_distance_orders
      case {state.direction, order.type} do
          {:idle, _} -> distance_between_orders(state, order)
          {_, :cab} -> distance_between_orders(state, order)
          _other ->
            simulate_elevator(0, state, order)
      end
  end

  def compute_cost_all_orders(state, orders) do
      Enum.map(orders, fn order ->  %Order{order | cost: order.cost + compute_cost_order(state, order)} end) |>
      Enum.sort_by(& &1.cost)
  end

end
