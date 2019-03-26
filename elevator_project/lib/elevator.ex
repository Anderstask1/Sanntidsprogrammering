defmodule Elevatorm do
<<<<<<< HEAD
  # JMPT: I suggest using GenServer(Elixir Generic server) for the state machine

=======
>>>>>>> 2a56832c09923e86b5a700c6793856a772a78496
  @moduledoc """
  This is the Elevator module
  """
  def start_working(pid_distributor) do
    {:ok, pid_driver} = Driver.start()            #setup driver connection
    {:ok,  pid_FSM  } = ElevatorFSM.start_link()  #connect_FSM()
    go_to_know_state(pid_FSM, pid_driver, pid_distributor)
    retrieve_local_backup(self(), pid_FSM, pid_driver, pid_distributor)
    spawn fn -> ElevatorFSM.order_collector(self(), pid_driver, pid_distributor) end
    spawn fn -> ElevatorFSM.floor_collector(self(), pid_driver, pid_distributor, pid_FSM) end
    receive_orders_loop(pid_distributor, pid_FSM, pid_driver)
  end

<<<<<<< HEAD
  IO.puts("This only runs during compilation...")

  # #GenServer callbacks
  #
  # @impl true #this makes the compiler  warn if the current module has no
  #            #behaviour that requires the handle function to be implemented
  # def init(pid) do
  #   {ok,pid}
  # end
  #
  # @impl true
  # def handle_button_state(pid,button_type) do
  #
  # end
  #
  # @impl true
  # def handle_floor_change(pid, floor) do
  #
  # end
  #
  # @impl true
  # def handle_stop_button(pid) do
  #
  # end
  #
  # @impl true
  # def handle_obstruction(pid) do
  #
  # end

  @doc """
  this function controls a single elevator to go up to 3 floor and the down to 0
  """
  def simple_ele() do
    # setup the elevator driver
    {:ok, driver_pid} = Driver.start()

    if Driver.set_floor_indicator(driver_pid, 2) == :between_floors do
      IO.puts("The cab is between floors")
    end

    # Elevator go down!
    Driver.set_motor_direction(driver_pid, :down)

    until_reach_floor(driver_pid, 0)
    IO.puts("Elevator is in floor 0")
    # Elevator go up!
    Driver.set_motor_direction(driver_pid, :up)

    until_reach_floor(driver_pid, 3)
    IO.puts("Elevator is in floor 3")
    # Elevator go down!
    Driver.set_motor_direction(driver_pid, :down)

    until_reach_floor(driver_pid, 0)
    IO.puts("Elevator is in floor 0")

    # Stops the connection with the Elevator server
    Driver.stop(driver_pid)
    # Driver.set_motor_direction(driver_pid, :stop) can be used instead for
    # stopping the elevator whiout disconnecting with the server
=======


  def receive_orders_loop(pid_distributor, pid_FSM, pid_driver) do
    receive do

      {:ok, pid_sender, complete_system} ->

        if pid_sender != pid_distributor do
          IO.puts "I am receiving a complete_system from an unexpected distributor"
        end

        store_local_backup(complete_system)
        {state,_floor,_movement}= ElevatorFSM.get_state(pid_FSM)
        ip = get_my_local_ip()
        my_elevator = Enum.find(complete_system, fn elevator -> elevator.ip == ip end)
        if state == :IDLE do
          if my_elevator.orders != [] do
            order=List.first(my_elevator.orders).floor
            sender=self()
            spawn fn->elevator_loop(sender,pid_FSM, pid_driver,pid_distributor, order) end
            ElevatorFSM.send_status(pid_FSM, pid_distributor, self())
          end
        end

        light_orders=my_elevator.lights
        if light_orders != [] do
          Enum.map(light_orders, fn x -> action_light(x, pid_driver) end)
        end

      after
        9_000 -> IO.puts "No orders received after 9 seconds"

    end
    receive_orders_loop(pid_distributor, pid_FSM, pid_driver)
  end



  def elevator_loop(sender,pid_FSM, pid_driver, pid_distributor, order) do
    ElevatorFSM.new_order(pid_FSM, pid_driver, order)

    {_state,current_floor,_movement} = ElevatorFSM.get_state(pid_FSM)
    if current_floor == order do
      ElevatorFSM.arrived(pid_FSM, pid_driver)
      ElevatorFSM.send_status(pid_FSM, pid_distributor, sender)
      open_doors(pid_driver)
      ElevatorFSM.continue_working(pid_FSM)
      ElevatorFSM.send_status(pid_FSM, pid_distributor, sender)
      :timer.sleep(100);
      Process.exit(self(), :kill)
    end
      ElevatorFSM.update_floor(pid_FSM, pid_driver)
      :timer.sleep(100);
      elevator_loop(sender,pid_FSM, pid_driver, pid_distributor, order)
  end


###############################################################################
###############################################################################
###############################################################################
  @doc """
    Moves the elevator to a known state in the case that the elevator is
    not exciting any floor sensor.
  """
  def go_to_know_state(pid_FSM, pid_driver, pid_distributor) do
    if Driver.get_floor_sensor_state(pid_driver) == :between_floors do
      {_state,_floor,movement}= ElevatorFSM.get_state(pid_FSM)
      if movement != :moving_down do
        ElevatorFSM.set_status(pid_FSM, :MOVE ,:unspecified ,:moving_down, pid_distributor)
        Driver.set_motor_direction(pid_driver, :down)
      end
      go_to_know_state(pid_FSM, pid_driver, pid_distributor)
    else
      Driver.set_motor_direction(pid_driver, :stop)
      floor = Driver.get_floor_sensor_state(pid_driver)
      ElevatorFSM.set_status(pid_FSM, :IDLE ,floor ,:stopped, pid_distributor)
      :ok
    end
  end

  @doc """
    Tries to open the backup file and, if it exists, move the elevator to the
    previous status that was stored in the backup. It also send the backup file
    to the
  """
  def retrieve_local_backup(sender, pid_FSM, pid_driver, pid_distributor)  do
     case File.read "local_backup" do
       {:ok, data} ->
         IO.puts "There is a backup avalieble"
         complete_system = :erlang.binary_to_term(data)
         ip = get_my_local_ip()
         case Enum.find(complete_system, fn elevator -> elevator.ip == ip end) do
           :error -> :ok
           elevator ->
             IO.puts "The previous status was: #{inspect elevator.state}"
             floor = elevator.state.floor
             if Driver.get_floor_sensor_state(pid_driver) != floor do
               IO.puts "Calling elevator loop with status: #{inspect ElevatorFSM.get_state(pid_FSM)}"
               IO.puts "for going to floor: #{inspect floor}"
               sender=self()
               spawn fn -> elevator_loop(sender,pid_FSM, pid_driver, pid_distributor, floor) end
               :timer.sleep(9000);
             end
             ElevatorFSM.set_status(pid_FSM, :IDLE ,floor ,:stopped,pid_distributor)
             ElevatorFSM.send_status(pid_FSM, pid_distributor, sender)
         end
       {:error, :enoent} -> :unspecified
     end
  end



  def get_orders(_list) do
    #==========================================================================
    # TO DO: Handle the receive from the distributor keeping the complete
    # list of orders
    receive do
      {:complete_system, complete_system} ->
      store_local_backup(complete_system)
      List.first(complete_system).ip
    after
      5_000 -> IO.puts "Notify observer"#notify_observer()
    end
  end

  @doc """
    Turn on the "door opened" light for 3 seconds. It is important to note that
    the code running blocks when calling this for 3 seconds.
  """
  def open_doors(pid_driver) do
    Driver.set_door_open_light(pid_driver, :on)
    :timer.sleep(3000);
    Driver.set_door_open_light(pid_driver, :off)
>>>>>>> 2a56832c09923e86b5a700c6793856a772a78496
  end


  @doc """
    This function stores the status of the complete system using the file
    library. It either create a new file in the same folder that this module or
    overwrite the existing one. In order to store complex structures and lists
    the conversion of the Erlang library term_to_binary is conducted. It is
    important to reconvert it to term using binary_to_term to recover the same
    data structure.
  """
<<<<<<< HEAD
  def until_reach_floor(driver_pid, floor) do
    # Blocks the code execution until the floor is changed to the value of floor
    if floor != Driver.get_floor_sensor_state(driver_pid) do
      until_reach_floor(driver_pid, floor)
    else
      :ok
    end
=======
  def store_local_backup(complete_system) do
    {:ok, file} = File.open("local_backup", [:write])
    IO.binwrite(file,:erlang.term_to_binary(complete_system))
    File.close(file)
>>>>>>> 2a56832c09923e86b5a700c6793856a772a78496
  end

  @doc """
    This function returns the value of the local IP adrres. It works both in
    Windows and Ubuntu.
  """
<<<<<<< HEAD
  def server(name) do
    # To run this function:
    #   iex -S mix
    #   iex(2)> server_1=spawn(fn -> Elevator.server("server_1") end)
    #   send(server_1, "here the message") // This is the testing
    # Wait here until I receive something :D
    receive do
      message -> IO.puts("Server #{name} received #{message}")
    end

    Elevatorm.server(name)
=======
  def get_my_local_ip do
    case :inet.getif() do
        {:ok, [{ip, _defini1, _mask1}, {_nope, _defini, _mask2}]} ->   ip
        {:ok, [_none1, {ip, _none2, _none3}, _none4]} -> ip
    end
  end

  def pid(string) when is_binary(string) do
    :erlang.list_to_pid('<#{string}>')
  end

  def action_light(pid, light) do
    Driver.set_order_button_light(pid, light.type, light.floor, light.state)
>>>>>>> 2a56832c09923e86b5a700c6793856a772a78496
  end
end
