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

  # def get_state(pid_FSM) do
  #     GenServer.call(pid_FSM, :get_state)
  # end
  #
  # def update_movement(pid_FSM, new_movement) do
  #    GenServer.cast(pid_FSM, {:update_movement, new_movement})
  # end
  #
  # def update_floor(pid_FSM, pid_driver) do
  #    GenServer.cast(pid_FSM, {:update_floor, pid_driver})
  # end
  #
  # def handle_call(:get_state, _from, state) do
  #   {:reply, state, state}
  # end
  #
  # def handle_cast({:update_movement, new_movement},{state,floor,movement}) do
  #   if new_movement == movement do
  #     {:noreply, {state,floor, movement}}
  #   else
  #     if new_movement ==  :stopped do
  #       {:noreply, {:IDLE,floor, new_movement}}
  #     else
  #       {:noreply, {:MOVE,floor, new_movement}}
  #     end
  #   end
  # end
  #
  # def handle_cast({:update_floor, pid_driver},{state,floor,movement}) do
  #   new_floor = Driver.get_floor_sensor_state(pid_driver)
  #   if floor == :unknow_floor do
  #     #IO.puts "Unknown floor"
  #   end
  #   if new_floor == :between_floors do
  #     {:noreply, {state, floor ,movement}}
  #   else
  #     {:noreply, {state,new_floor ,movement}}
  #   end
  # end

  def init(initial_data) do #set the initial state
    {:ok, initial_data}
  end

  def start do
    start {127,0,0,1}, 15657 #calls function bellow with correct adress and port
  end

  def start address, port do
    GenServer.start_link(__MODULE__, [address, port], [])
  end

  def start complete_list do
    GenServer.start_link(__MODULE__, complete_list, [])
  end

  def get_state(pid_complete_list) do
      GenServer.call(pid_complete_list, :get_state)
  end

  def update_complete_list(pid_complete_list, new_elevator) do
    GenServer.cast(pid_complete_list, {:update_complete_list, new_elevator})
  end

  #============ CAST AND CALLS ===================

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:update_complete_list, new_elevator}, complete_list) do
    {:noreply, complete_list ++ [new_elevator]}
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

  def update_system_list(sender_pid, state = %State{}) do
    elevator = CompleteSystem.elevator_by_pid(:find, complete_list, sender_pid)
    %{elevator | state: state}
    CompleteSystem.elevator_by_pid(:replace, complete_list, sender_pid, elevator)
    update_orders_completed(sender_pid, state)
  end

  def update_system_list(sender_pid, order = %Order{}) do
    elevator = CompleteSystem.elevator_by_pid(:find, complete_list, sender_pid)
    %{elevator | orders: elevator.orders ++ order}
    CompleteSystem.elevator_by_pid(:replace, complete_list, sender_pid, elevator)
  end

  def update_orders_completed(sender_pid, state, iterate \\ 0) do
    elevator = CompleteSystem.elevator_by_pid(:find, complete_list, sender_pid)
    orders = elevator.orders
    order = Enum.at(orders, iterate)
    if is_same_floor_same_direction(state, order) do
      %{elevator | orders: List.delete_at(orders, iterate)}
      CompleteSystem.elevator_by_pid(:replace, complete_list, sender_pid, elevator)
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
      Enum.map(orders, fn order ->  %Order{order | cost: order.cost + compute_cost_order(state, order)} end) |>
      Enum.sort_by(& &1.cost)
  end
end
