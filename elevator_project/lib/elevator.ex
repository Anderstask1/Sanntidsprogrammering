defmodule Elevatorm do
  @moduledoc """
  This is the Elevator module
  """
  def start do
    {:ok, pid_driver} = Driver.start()
    IO.puts("Driver connected")
    {:ok, pid_FSM} = ElevatorFSM.start_link()
    IO.puts("FSM started")
    go_to_know_state(pid_driver)
    retrieve_local_backup()
    IO.puts("Spawn collectors")
    pid_elevator = self()
    IO.puts("STATE IS SET TO #{inspect ElevatorFSM.get_state()}")
    ElevatorFSM.send_status()

    pid_order_collector = spawn(fn -> ElevatorFSM.order_collector(pid_driver) end)
    pid_floor_collector = spawn(fn -> ElevatorFSM.floor_collector(pid_driver, pid_FSM) end)

    IO.puts("======================================")
    IO.puts("=DRIVER           #{inspect(pid_driver)}")
    IO.puts("=FSM_ELEVATOR     #{inspect(pid_FSM)}")
    IO.puts("=ELEVATOR         #{inspect(pid_elevator)}")
    IO.puts("=ORDER COLLECTOR  #{inspect(pid_order_collector)}")
    IO.puts("=FLOOR COLLECTOR  #{inspect(pid_floor_collector)}")
    IO.puts("======================================")
    all_pids=[pid_order_collector,pid_floor_collector,pid_FSM, pid_driver]
    IO.puts("=FLOOR COLLECTOR  #{inspect(pid_floor_collector)}")
    Distributor.add_to_complete_list(Distributor.get_elevator_in_complete_list(Node.self(), Distributor.get_complete_list()),Node.self())
    executing_orders_loop(pid_FSM, pid_driver, all_pids,[])
  end

  def executing_orders_loop(pid_FSM, pid_driver, all_pids, previus_lights) do
    complete_system = Distributor.get_complete_list()
    #ip = get_my_local_ip()
    ip = Node.self()
    my_elevator = Enum.find(complete_system, fn elevator -> elevator.ip == ip end)
    if my_elevator.harakiri do
      #I have to kill myself
      Enum.map(all_pids, fn pid -> Process.exit(pid, :kill) end)
      IO.puts "Bye ;( "
      Process.exit(self(), :kill)
    else
      store_local_backup(complete_system)
      {_state, _floor, movement} = ElevatorFSM.get_state()
      ElevatorFSM.send_status()
      if movement == :idle do
        if my_elevator.orders != [] do
          order = List.first(my_elevator.orders).floor
          IO.puts("ELEV order taken #{inspect order} from node #{inspect Node.self()}")
          spawn(fn -> elevator_loop(pid_FSM, pid_driver, order) end)
          ElevatorFSM.send_status()
        end
      end
      light_orders = my_elevator.lights
      if light_orders != [] and light_orders != previus_lights do
        Enum.map(light_orders, fn light -> action_light(light, pid_driver) end)
      end
    end
    :timer.sleep(200)
    executing_orders_loop(pid_FSM, pid_driver, all_pids, my_elevator.lights)
  end

  def elevator_loop(pid_FSM, pid_driver, order) do
    {_state, current_floor, _movement} = ElevatorFSM.get_state()
    ElevatorFSM.new_order(pid_driver, order)
    if current_floor == order do
      Driver.set_motor_direction(pid_driver, :stop)
      ElevatorFSM.arrived(pid_driver)
      open_doors(pid_driver)
      ElevatorFSM.continue_working()
      :timer.sleep(100)
      ElevatorFSM.send_status()
      Process.exit(self(), :kill)
    end
    :timer.sleep(100)
    elevator_loop(pid_FSM, pid_driver, order)
  end

  ###############################################################################
  ###############################################################################
  ###############################################################################
  @doc """
    Moves the elevator to a known state in the case that the elevator is
    not exciting any floor sensor.
  """
  def go_to_know_state(pid_driver) do

    if Driver.get_floor_sensor_state(pid_driver) == :between_floors do
      {_state, _floor, movement} = ElevatorFSM.get_state()

      if movement != :down do
        ElevatorFSM.set_status(:MOVE, :unspecified, :down)
        Driver.set_motor_direction(pid_driver, :down)
      end

      go_to_know_state(pid_driver)
    else
      Driver.set_motor_direction(pid_driver, :stop)
      floor = Driver.get_floor_sensor_state(pid_driver)
      ElevatorFSM.set_status(:IDLE, floor, :idle)
      IO.puts("==========Sending status")
      :ok
    end
  end

  @doc """
    Tries to open the backup file and, if it exists, move the elevator to the
    previous status that was stored in the backup. It also send the backup file
    to the
  """
  def retrieve_local_backup do
    case File.read("local_backup") do
      {:ok, data} ->
        IO.puts("£  There is a backup avalible")
        complete_system = :erlang.binary_to_term(data)
        ip = Node.self()
        my_elevator = Enum.find(complete_system, fn elevator -> elevator.ip == ip end)
        IO.puts("My elevator system retrieved : #{inspect(complete_system)}")
        IO.puts("Sending backup the elevator to the distributor")
        Enum.each(my_elevator.orders, fn order -> Distributor.send_order(order,ip) end)
        IO.puts(" STATE IS SET TO #{inspect my_elevator.state}")
        Distributor.send_state(my_elevator.state, ip)
        Distributor.send_lights(my_elevator.lights, ip)
      {:error, :enoent} ->
        IO.puts("£  There is no backup, lets create one")
        ip = Node.self()
        complete_system = CompleteSystem.init_list(ip)
        my_elevator = Enum.find(complete_system, fn elevator -> elevator.ip == ip end)
        IO.puts("Sending backup from elevator to the distributor")
        Enum.each(my_elevator.orders, fn order -> Distributor.send_order(order,ip) end)
        IO.puts(" STATE IS SET TO #{inspect my_elevator.state}")
        Distributor.send_state(my_elevator.state,ip)
        Distributor.send_lights(my_elevator.lights,ip)
      unspected ->
        IO.puts("Unespected read result : #{inspect(unspected)}")
    end
  end

  def get_orders(_list) do
    # ==========================================================================
    # TO DO: Handle the receive from the distributor keeping the complete
    # list of orders
    receive do
      {:complete_system, complete_system} ->
        store_local_backup(complete_system)
        List.first(complete_system).ip
    after
      # notify_observer()
      5_000 -> IO.puts("Notify observer")
    end
  end

  @doc """
    Turn on the "door opened" light for 3 seconds. It is important to note that
    the code running blocks when calling this for 3 seconds.
  """
  def open_doors(pid_driver) do
    Driver.set_door_open_light(pid_driver, :on)
    :timer.sleep(3000)
    Driver.set_door_open_light(pid_driver, :off)
  end

  @doc """
    This function stores the status of the complete system using the file
    library. It either create a new file in the same folder that this module or
    overwrite the existing one. In order to store complex structures and lists
    the conversion of the Erlang library term_to_binary is conducted. It is
    important to reconvert it to term using binary_to_term to recover the same
    data structure.
  """
  def store_local_backup(complete_system) do
    {:ok, file} = File.open("local_backup", [:write])
    IO.binwrite(file, :erlang.term_to_binary(complete_system))
    File.close(file)
  end

  @doc """
    This function returns the value of the local IP adrres. It works both in
    Windows and Ubuntu.
  """
  def get_my_local_ip do
    case :inet.getif() do
      {:ok, [{ip, _defini1, _mask1}, {_nope, _defini, _mask2}]} -> ip
      {:ok, [_none1, {ip, _none2, _none3}, _none4]} -> ip
    end
  end

  def pid(string) when is_binary(string) do
    :erlang.list_to_pid('<#{inspect(string)}>')
  end

  def action_light(light, pid) do
    if light != [] do
      Driver.set_order_button_light(pid, light.type, light.floor, light.state)
    end
  end
end

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

  def get_state() do#used
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

  def continue_working() do#used
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

  def send_status() do
    GenServer.cast(:genelevator, :send_status)
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
    if new_floor == :between_floors do
      {:noreply, {state, floor, movement}}
    else
      {:noreply, {state, new_floor, movement}}
    end
  end

  def handle_cast({:arrived, _pid_driver}, {_state, floor, movement}) do
    {:noreply, {:ARRIVED_FLOOR, floor, movement}}
  end

  def handle_cast(:continue_working, {_state, floor, _movement}) do
    {:noreply, {:IDLE, floor, :idle}}
  end

  def handle_cast(:still_in_previous_order, {_state, floor, movement}) do
    {:noreply, {:ARRIVED_FLOOR, floor, movement}}
  end

  def handle_cast({:new_order, pid_driver, order}, {state, floor, movement}) do
    if order != floor and movement == :idle do
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

  def handle_cast(:send_status, {state, floor, movement}) do
    Distributor.send_state(State.init(movement, floor), Node.self())
    {:noreply, {state, floor, movement}}
  end

  # ===============================================================================
  # =================    ADITIONAL UTILITIES           ============================
  # ===============================================================================

  @doc """
    This function runs the loop the recursive function order_collector/5 with an
    empty previus orders.
  """
  def order_collector(pid_driver) do
    order_collector(pid_driver, [], [], [])
  end

  @doc """
    This function runs in loop indefinitely constantly asking to the Elevator
    Driver if there is any buttom pushed. If so, the loop send the order to the
    distributor using the function send_buttons/3.
  """
  def order_collector(
        pid_driver,
        previous_cabs,
        previous_up,
        previous_down
      ) do
    cabs =
      Enum.filter(@bottom_floor..@top_floor, fn x ->
        Driver.get_order_button_state(pid_driver, x, :cab) == 1
      end)

    if cabs != [] do
      send_buttons(:cab, cabs, previous_cabs)
    end

    hall_up =
      Enum.filter(@bottom_floor..@top_floor, fn x ->
        Driver.get_order_button_state(pid_driver, x, :hall_up) == 1
      end)

    if hall_up != [] do
      send_buttons(:hall_up, hall_up, previous_up)
    end

    hall_down =
      Enum.filter(@bottom_floor..@top_floor, fn x ->
        Driver.get_order_button_state(pid_driver, x, :hall_down) == 1
      end)

    if hall_down != [] do
      send_buttons(:hall_down, hall_down, previous_down)
    end

    order_collector(pid_driver, cabs, hall_up, hall_down)
  end

  @doc """
    This function send to the distributor the buttoms that are pushed if the
    buttoms are different from the previous pushes. This is done to avoid
    sending redundant orders. Returns :ok when the send is completed.
  """
  def send_buttons(button_type, floors, previous) do
    if length(floors) == 1 and floors != previous do
      Enum.map(floors, fn x ->
        #send(pid_distributor, {:order, pid_send, Order.init(button_type, x)})
        Distributor.send_order(Order.init(button_type, x), Node.self())
      end)
    end
  end

  def floor_collector(pid_driver) do
    floor_collector(pid_driver,Driver.get_floor_sensor_state(pid_driver))
  end
  def floor_collector(pid_driver, previous_floor) do
    new_floor = Driver.get_floor_sensor_state(pid_driver)
    if previous_floor != new_floor and new_floor != :between_floors do
      update_floor(pid_driver)
      Driver.set_floor_indicator(pid_driver, new_floor)
      {_state, _floor, movement} = get_state()
      Distributor.send_state(State.init(movement, new_floor), Node.self())
    end

    floor_collector(pid_driver, new_floor)
  end
end
