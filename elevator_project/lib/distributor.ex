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

  def hello do
      @doc """
      this function says hello
      """
    IO.puts "Hello brothers and sisters"
    :world
  end

  def direction_to_integer(state) do
      @doc """
      this function converts the direction in atoms to an integer
      INPUT:
        - touple with state of elevator, containing direction and floor (unused)
      OUTPUT:
        - integer where up = 1, down = -1 and idle = 0
      """
      case state do
          {:up, _} -> 1
          {:idle, _} -> 0
          {:down, _} -> -1
          _ -> :error
  end

  def traverse_orders() do
      @doc """
      this function goes through each element of the list
      """
  end

  def number_of_orders(orders) do
      @doc """
      this function count the number of orders of a single elevator
      INPUT:
        - orders of the elevator
      OUTPUT:
        - number of orders
      """
      length(orders)
  end

  def distance_between_orders(state, order) do
      @doc """
      this function computes number of floors between a state and an order
      """
      current_floor = state |> elem(1) # extract second element of tuple
      abs(current_floor - order)
  end

  def compare_order_state(order, state) do

  end

  def simulate_elevator(duration, state, order) do
      if order.type == :cab or order.floor == @top or order.floor == @bottom or
        duration
      else
        case state do
            {:up, @top} -> state = %State{state | direction: :down}
            {:down, @bottom} -> state = %State{state | direction: :up}
            _ -> state = %State{state | floor: state.floor + direction_to_integer(state)}
        end
        simulate_elevator(duration+1, state, order)
      end
  end

  def compute_cost_order(state, order) do
      @doc """
      this function compute the cost for a single elevator.
      INPUT:
        - state and orders of a single elevator, and the new order
      OUTPUT:
        - the cost of taking the order for that elevator, a higher number indicates a high cost for taking the order
      """
      #first_order_floor = Enum.fetch(orders, 0) # extract first element of list
      #weight_nr_orders = 10
      #weight_distance_orders = 1
      #number_of_orders(orders)*weight_nr_orders + distance_between_orders(state, new_order)*weight_distance_orders
      case state do
          :idle ->
            distance_between_orders(state, order)
          _other ->
            simulate_elevator(0, state, order)
      end
  end

  def compute_cost_all_orders(state, orders) do
      order = %Order{order | cost: order.cost + compute_cost_order(state, orders, new_order)}
  end

end
