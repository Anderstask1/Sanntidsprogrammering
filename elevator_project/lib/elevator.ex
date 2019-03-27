defmodule Elevatorm do
  @moduledoc """
  This is the Elevator module
  """
  def start_working do
    IO.puts("I am listening with pid #{inspect(self())}")

    receive do
      {:ok, pid_distributor, _} ->
        IO.puts("Empty list received from distributor #{inspect(pid_distributor)}")
        # setup driver connection
        {:ok, pid_driver} = Driver.start()
        IO.puts("Driver connected")
        # connect_FSM()
        {:ok, pid_FSM} = ElevatorFSM.start_link()
        IO.puts("FSM started")
        go_to_know_state(pid_FSM, pid_driver, pid_distributor)
        retrieve_local_backup(self(), pid_FSM, pid_distributor)
        IO.puts("Spawn collectors")
        pid_elevator = self()
        ElevatorFSM.send_status(pid_FSM, pid_distributor, pid_elevator)

        pid_order_collector =
          spawn(fn -> ElevatorFSM.order_collector(pid_elevator, pid_driver, pid_distributor) end)

        pid_floor_collector =
          spawn(fn ->
            ElevatorFSM.floor_collector(pid_elevator, pid_driver, pid_distributor, pid_FSM)
          end)

        IO.puts("Entering receiving loop")
        IO.puts("======================================")
        IO.puts("DISTRIBUTOR      #{inspect(pid_distributor)}")
        IO.puts("DRIVER           #{inspect(pid_driver)}")
        IO.puts("FSM_ELEVATOR     #{inspect(pid_FSM)}")
        IO.puts("ELEVATOR         #{inspect(pid_elevator)}")
        IO.puts("ORDER COLLECTOR  #{inspect(pid_order_collector)}")
        IO.puts("FLOOR COLLECTOR  #{inspect(pid_floor_collector)}")
        IO.puts("======================================")
        receive_orders_loop(pid_distributor, pid_FSM, pid_driver)

      message ->
        IO.puts(
          "Error elevator module: unexpected message before initialization #{inspect(message)}"
        )
    end
  end

  def receive_orders_loop(pid_distributor, pid_FSM, pid_driver) do
    receive do
      {:ok, pid_sender, complete_system} ->
        IO.puts("Complete system received #{inspect(complete_system)}")

        if pid_sender != pid_distributor do
          IO.puts("I am receiving a complete_system from an unexpected distributor")
        end

        store_local_backup(complete_system)
        {state, _floor, _movement} = ElevatorFSM.get_state(pid_FSM)
        ip = get_my_local_ip()
        my_elevator = Enum.find(complete_system, fn elevator -> elevator.ip == ip end)

        if state == :IDLE do
          if my_elevator.orders != [] do
            order = List.first(my_elevator.orders).floor
            sender = self()
            spawn(fn -> elevator_loop(sender, pid_FSM, pid_driver, pid_distributor, order) end)
            ElevatorFSM.send_status(pid_FSM, pid_distributor, self())
          end
        end

        light_orders = my_elevator.lights

        if light_orders != [] do
          IO.puts("----- HANDLE LIGHTS #{inspect(light_orders)}")
          Enum.map(light_orders, fn x -> action_light(x, pid_driver) end)
        end
    after
      9_000 -> IO.puts("No orders received after 9 seconds")
    end

    receive_orders_loop(pid_distributor, pid_FSM, pid_driver)
  end

  def elevator_loop(sender, pid_FSM, pid_driver, pid_distributor, order) do
    ElevatorFSM.new_order(pid_FSM, pid_driver, order)

    {_state, current_floor, _movement} = ElevatorFSM.get_state(pid_FSM)

    if current_floor == order do
      ElevatorFSM.arrived(pid_FSM, pid_driver)
      ElevatorFSM.send_status(pid_FSM, pid_distributor, sender)
      open_doors(pid_driver)
      ElevatorFSM.continue_working(pid_FSM)
      ElevatorFSM.send_status(pid_FSM, pid_distributor, sender)
      :timer.sleep(100)
      Process.exit(self(), :kill)
    end

    ElevatorFSM.update_floor(pid_FSM, pid_driver)
    :timer.sleep(100)
    elevator_loop(sender, pid_FSM, pid_driver, pid_distributor, order)
  end

  ###############################################################################
  ###############################################################################
  ###############################################################################
  @doc """
    Moves the elevator to a known state in the case that the elevator is
    not exciting any floor sensor.
  """
  def go_to_know_state(pid_FSM, pid_driver, pid_distributor) do
    IO.puts("Moving to know state")

    if Driver.get_floor_sensor_state(pid_driver) == :between_floors do
      {_state, _floor, movement} = ElevatorFSM.get_state(pid_FSM)

      if movement != :down do
        ElevatorFSM.set_status(pid_FSM, :MOVE, :unspecified, :down)
        Driver.set_motor_direction(pid_driver, :down)
      end

      go_to_know_state(pid_FSM, pid_driver, pid_distributor)
    else
      Driver.set_motor_direction(pid_driver, :stop)
      floor = Driver.get_floor_sensor_state(pid_driver)
      ElevatorFSM.set_status(pid_FSM, :IDLE, floor, :idle)
      ElevatorFSM.send_status(pid_FSM, pid_distributor, self())
      :ok
    end
  end

  @doc """
    Tries to open the backup file and, if it exists, move the elevator to the
    previous status that was stored in the backup. It also send the backup file
    to the
  """
  def retrieve_local_backup(sender, pid_FSM, pid_distributor) do
    case File.read("local_backup") do
      {:ok, data} ->
        IO.puts("
        £££££££££££££££££££££££££££££££££££££££££££££££££
        £  There is a backup avalible
        £££££££££££££££££££££££££££££££££££££££££££££££££
         ")
        complete_system = :erlang.binary_to_term(data)
        ip = get_my_local_ip()
        my_elevator = Enum.find(complete_system, fn elevator -> elevator.ip == ip end)
        IO.puts("My elevator system retrieved : #{inspect(complete_system)}")
        IO.puts("Sending backup the elevator to the distributor")
        send(pid_distributor, {:elevator_backup, sender, my_elevator})

      {:error, :enoent} ->
        IO.puts("
         ££££££££££££££££££££££££££££££££££££££££££££££££££
         £  There is no backup, lets create one
         ££££££££££££££££££££££££££££££££££££££££££££££££££
         ")
        complete_system = CreateList.init_list_fake(get_my_local_ip(), self())
        ip = get_my_local_ip()
        my_elevator = Enum.find(complete_system, fn elevator -> elevator.ip == ip end)
        IO.puts("My elevator system retrieved : #{inspect(complete_system)}")
        IO.puts("Sending backup the elevator to the distributor")
        send(pid_distributor, {:elevator_backup, sender, my_elevator})

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
    IO.puts("Set light: #{inspect(light)}")
    Driver.set_order_button_light(pid, light.type, light.floor, light.state)
  end
end
