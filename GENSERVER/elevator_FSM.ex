defmodule ElevatorFSM do
  use GenServer
  

  @moduledoc """
  This is the Finite State Machine module of the elevator. This keeps track of
  the state of the elevator cabin.

  This module implments a FSM with 3 main states:
    :IDLE
    :MOVE
    :ARRIVED_FLOOR
  -> Inside the :MOVE status the cab can be :stopped, :moving_up and :moving_down .
  -> The FSM includes the floor as well.

    The state of the FSM is managed in a tuple-form-state, this tuple stores the
    following vales:

      state = {status, floor, movement}

        ->status describes the main state (:IDLE, :MOVE or :ARRIVED_FLOOR)

        ->floor stores the current floor of the cab, it is important to note
        that the floor value is always a integer representing the number of
        the floor. If the cab is between floors the Driver interface return
        the atom :between_floors but this module do not update the floor if
        called with this value.

        ->movement describe the movement of the cab, can be :stopped,
        :moving_up or :moving_down
  """



  def start_link() do
    GenServer.start_link(ElevatorFSM, {:IDLE,:unknow_floor,:stopped})
    end

  def init(initial_data) do #set the initial state
    {:ok, initial_data}
    end

  def get_state(pid_FSM) do
      GenServer.call(pid_FSM, :get_state)
  end

  def update_movement(pid_FSM, new_movement) do
     GenServer.cast(pid_FSM, {:update_movement, new_movement})
  end

  def update_floor(pid_FSM, pid_driver) do
     GenServer.cast(pid_FSM, {:update_floor, pid_driver})
  end

  def arrived(pid_FSM, pid_driver) do
     GenServer.cast(pid_FSM,{:arrived, pid_driver})
  end

  def continue_working(pid_FSM) do
     GenServer.cast(pid_FSM, :continue_working)
  end

  def still_in_previous_order(pid_FSM) do
     GenServer.cast(pid_FSM, :still_in_previous_order)
  end

  def new_order(pid_FSM, pid_driver, order) do
     GenServer.cast(pid_FSM, {:new_order,pid_driver, order})
  end

  def set_status(pid_FSM, state,floor,movement) do
    GenServer.cast(pid_FSM, {:set_status,state,floor,movement})
  end



#========== CAST AND CALLS ==========================



  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:update_movement, new_movement},{state,floor,movement}) do
    if new_movement == movement do
      {:noreply, {state,floor, movement}}
    else
      if new_movement ==  :stopped do
        {:noreply, {:IDLE,floor, new_movement}}
      else
        {:noreply, {:MOVE,floor, new_movement}}
      end
    end
  end

  def handle_cast({:update_floor, pid_driver},{state,floor,movement}) do
    new_floor = Driver.get_floor_sensor_state(pid_driver)
    if floor == :unknow_floor do
      #IO.puts "Unknown floor"
    end
    if new_floor == :between_floors do
      {:noreply, {state, floor ,movement}}
    else
      {:noreply, {state,new_floor ,movement}}
    end
  end

  def handle_cast({:arrived, pid_driver} ,{_state,floor,_movement}) do
    Driver.set_motor_direction(pid_driver, :stop)
    {:noreply, {:ARRIVED_FLOOR, floor ,:stopped}}
  end

  def handle_cast(:continue_working ,{_state,floor,movement}) do
    {:noreply, {:IDLE, floor ,movement}}
  end

  def handle_cast(:still_in_previous_order ,{_state,floor,movement}) do
    {:noreply, {:ARRIVED_FLOOR, floor ,movement}}
  end

  def handle_cast({:new_order,pid_driver, order},{state,floor,movement}) do
    if state == :IDLE do
      if order > floor do
        Driver.set_motor_direction(pid_driver, :up)
        #IO.puts "Moving up"
        {:noreply, {:MOVE,floor,:moving_up}}
      else
        Driver.set_motor_direction(pid_driver, :down)
        #IO.puts "Moving down"
        {:noreply, {:MOVE,floor,:moving_down}}
      end
    else
      {:noreply, {state,floor,movement}}
    end
  end

  def handle_cast({:set_status,state,floor,movement}, _oldstate) do
    #IO.puts "The pre-init status was: #{inspect oldstate}"
    {:noreply, {state, floor ,movement}}
  end


end
