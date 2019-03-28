defmodule ElevatorFSM do
  use GenServer

  @bottom_floor 0
  @top_floor 3

  @moduledoc """
  This is the Finite State Machine module of the elevator. This keeps track of
  the state of the elevator cabin.

  This module implments a FSM with 3 main states:
    :IDLE
    :MOVE
    :ARRIVED_FLOOR
  -> Inside the :MOVE status the cab can be :idle, :up and :down .
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

        ->movement describe the movement of the cab, can be :idle,
        :up or :down
  """

  def start_link() do
    GenServer.start_link(ElevatorFSM, {:IDLE, :unknow_floor, :idle}, name: :genelevator)
  end

  # set the initial state
  def init(initial_data) do
    {:ok, initial_data}
  end

  def get_state() do
    GenServer.call(:genelevator, :get_state)
  end

  def update_movement(new_movement) do
    GenServer.cast(:genelevator, {:update_movement, new_movement})
  end

  def update_floor(pid_driver) do
    GenServer.cast(:genelevator, {:update_floor, pid_driver})
  end

  def arrived(pid_driver) do
    GenServer.cast(:genelevator, {:arrived, pid_driver})
  end

  def continue_working() do
    GenServer.cast(:genelevator, :continue_working)
  end

  def still_in_previous_order() do
    GenServer.cast(:genelevator, :still_in_previous_order)
  end

  def new_order(pid_driver, order) do
    GenServer.cast(:genelevator, {:new_order, pid_driver, order})
  end

  def set_status(state, floor, movement) do
    GenServer.cast(:genelevator, {:set_status, state, floor, movement})
  end

  def send_status(pid_distributor, sender) do
    IO.puts("Inside send_status")
    IO.puts("pid distirbutor #{inspect(pid_distributor)}")
    IO.puts("pid sender      #{inspect(sender)}")
    GenServer.cast(:genelevator, {:send_status, pid_distributor, sender})
  end

  # ========== CAST AND CALLS ==========================

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:update_movement, new_movement}, {state, floor, movement}) do
    if new_movement == movement do
      {:noreply, {state, floor, movement}}
    else
      if new_movement == :idle do
        {:noreply, {:IDLE, floor, new_movement}}
      else
        {:noreply, {:MOVE, floor, new_movement}}
      end
    end
  end

  def handle_cast({:update_floor, pid_driver}, {state, floor, movement}) do
    new_floor = Driver.get_floor_sensor_state(pid_driver)

    if floor == :unknow_floor do
      # IO.puts "Unknown floor"
    end

    if new_floor == :between_floors do
      {:noreply, {state, floor, movement}}
    else
      {:noreply, {state, new_floor, movement}}
    end
  end

  def handle_cast({:arrived, pid_driver}, {_state, floor, _movement}) do
    Driver.set_motor_direction(pid_driver, :stop)
    {:noreply, {:ARRIVED_FLOOR, floor, :idle}}
  end

  def handle_cast(:continue_working, {_state, floor, movement}) do
    {:noreply, {:IDLE, floor, movement}}
  end

  def handle_cast(:still_in_previous_order, {_state, floor, movement}) do
    {:noreply, {:ARRIVED_FLOOR, floor, movement}}
  end

  def handle_cast({:new_order, pid_driver, order}, {state, floor, movement}) do
    if state == :IDLE do
      if order > floor do
        Driver.set_motor_direction(pid_driver, :up)
        {:noreply, {:MOVE, floor, :up}}
      else
        Driver.set_motor_direction(pid_driver, :down)

        {:noreply, {:MOVE, floor, :down}}
      end
    else
      {:noreply, {state, floor, movement}}
    end
  end

  def handle_cast({:set_status, state, floor, movement}, {_state, old_floor, _movement}) do
    IO.puts("Status set to  #{inspect(state)} / #{inspect(floor)}  /#{inspect(movement)}")

    if floor == :between_floors do
      {:noreply, {state, old_floor, movement}}
    else
      {:noreply, {state, floor, movement}}
    end
  end

  def handle_cast({:send_status, pid_distributor, sender}, {state, floor, movement}) do
    IO.puts(
      "Elevator #{inspect(sender)} sending(via send_status) to distributor #{
        inspect(pid_distributor)
      }   #{inspect(State.init(movement, floor))}"
    )

    # send(pid_distributor, {:state, sender, State.init(movement, floor)})
    send( pid_distributor, {:bad_nodes, self(), elem(Distributor.send_state(State.init(movement, floor)),1)})
    {:noreply, {state, floor, movement}}
  end

  # ===============================================================================
  # =================    ADITIONAL UTILITIES           ============================
  # ===============================================================================

  @doc """
    This function runs the loop the recursive function order_collector/5 with an
    empty previus orders.
  """
  def order_collector(pid_send, pid_driver, pid_distributor) do
    order_collector(pid_send, pid_driver, pid_distributor, [], [], [])
  end

  @doc """
    This function runs in loop indefinitely constantly asking to the Elevator
    Driver if there is any buttom pushed. If so, the loop send the order to the
    distributor using the function send_buttons/3.
  """
  def order_collector(
        pid_send,
        pid_driver,
        pid_distributor,
        previous_cabs,
        previous_up,
        previous_down
      ) do
    cabs =
      Enum.filter(@bottom_floor..@top_floor, fn x ->
        Driver.get_order_button_state(pid_driver, x, :cab) == 1
      end)

    if cabs != [] do
      send_buttons(pid_send, pid_distributor, :cab, cabs, previous_cabs)
    end

    hall_up =
      Enum.filter(@bottom_floor..@top_floor, fn x ->
        Driver.get_order_button_state(pid_driver, x, :hall_up) == 1
      end)

    if hall_up != [] do
      send_buttons(pid_send, pid_distributor, :hall_up, hall_up, previous_up)
    end

    hall_down =
      Enum.filter(@bottom_floor..@top_floor, fn x ->
        Driver.get_order_button_state(pid_driver, x, :hall_down) == 1
      end)

    if hall_down != [] do
      send_buttons(pid_send, pid_distributor, :hall_down, hall_down, previous_down)
    end

    order_collector(pid_send, pid_driver, pid_distributor, cabs, hall_up, hall_down)
  end

  @doc """
    This function send to the distributor the buttoms that are pushed if the
    buttoms are different from the previous pushes. This is done to avoid
    sending redundant orders. Returns :ok when the send is completed.
  """
  def send_buttons(pid_send, pid_distributor, button_type, floors, previous) do
    if length(floors) == 1 and floors != previous do
      Enum.map(floors, fn x ->
        IO.puts(
          "Elevator #{inspect(pid_send)} sending to distributor #{inspect(pid_distributor)}   #{
            inspect(Order.init(button_type, x))
          }"
        )
        #send(pid_distributor, {:order, pid_send, Order.init(button_type, x)})
        send( pid_distributor, {:bad_nodes, self(), elem(Distributor.send_order(Order.init(button_type, x)),1)})
      end)
    end

    :ok
  end

  def floor_collector(sender, pid_driver, pid_distributor, pid_FSM) do
    floor_collector(
      sender,
      pid_driver,
      pid_distributor,
      pid_FSM,
      Driver.get_floor_sensor_state(pid_driver)
    )
  end

  def floor_collector(sender, pid_driver, pid_distributor, pid_FSM, previous_floor) do
    new_floor = Driver.get_floor_sensor_state(pid_driver)
    :timer.sleep(5_000)
    if previous_floor != new_floor and new_floor != :between_floors do
      Driver.set_floor_indicator(pid_driver, new_floor)
      {_state, _floor, movement} = get_state()

      IO.puts(
        "Elevator #{inspect(sender)} sending to distributor #{inspect(pid_distributor)}   #{
          inspect(State.init(movement, new_floor))
        }"
      )

      # send(pid_distributor, {:state, sender, State.init(movement, new_floor)})
      send( pid_distributor, {:bad_nodes, self(), elem(Distributor.send_state(State.init(movement, new_floor)),1)})
    end

    floor_collector(sender, pid_driver, pid_distributor, pid_FSM, new_floor)
  end
end
