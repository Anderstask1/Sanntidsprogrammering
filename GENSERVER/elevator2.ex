defmodule Elevator do
  @moduledoc """
  This is the Elevator module
  """
  @bottom_floor 0
  @top_floor 3


  def start_working do
    {:ok, pid_driver} = Driver.start()            #setup driver connection
    {:ok,  pid_FSM  } = ElevatorFSM.start_link()  #connect_FSM()
    IO.puts "The FSM pid is #{inspect pid_FSM}"
    init_status=retrieve_local_backup()
    if Driver.get_floor_sensor_state(pid_driver) != 0 and init_status ==:unspecified do
      #No local backup avalible so go to floor 0
      set_state(init_status, pid_FSM, pid_driver)
      ElevatorFSM.set_status(pid_FSM, :IDLE,0,:stopped)
    else
      #There is a local backup stored in init_status
      IO.puts "We have a local backup"
    end
    IO.puts "Spawning loop"
    pid_receive_loop = spawn fn -> receive_orders_loop(pid_FSM, pid_driver) end
    loop_fake_distributor(pid_receive_loop)
  end

  def loop_fake_distributor(pid_receive_loop) do
    {order, _} = IO.gets("Enter floor order: ") |> Integer.parse
    send pid_receive_loop, {:new_order, self(), order}
    loop_fake_distributor(pid_receive_loop)
  end

  def receive_orders_loop(pid_FSM, pid_driver) do

    receive do
      {:new_order, pid_distributor, order} ->
        spawn fn -> elevator_loop(pid_FSM, pid_driver, pid_distributor, order) end
      after
        9_000 -> IO.puts "No orders received after 9 seconds"
    end
    receive_orders_loop(pid_FSM, pid_driver)
  end


  def elevator_loop(pid_FSM, pid_driver, pid_distributor, order) do
    ElevatorFSM.new_order(pid_FSM, pid_driver, order)

    {_state,current_floor,_movement} = ElevatorFSM.get_state(pid_FSM)
    if current_floor == order do
      ElevatorFSM.arrived(pid_FSM, pid_driver)
      #send_distributor_status(pid_driver)
      open_doors(pid_driver)
      ElevatorFSM.continue_working(pid_FSM)
      #send_distributor_status(pid_driver)
      :timer.sleep(100);
      Process.exit(self(), :kill)
    end
      ElevatorFSM.update_floor(pid_FSM, pid_driver)
      send_distributor_status(pid_driver)
      :timer.sleep(100);
      elevator_loop(pid_FSM, pid_driver, pid_distributor, order)
  end


###############################################################################
###############################################################################
###############################################################################
  def retrieve_local_backup()  do
    #TO DO: Complete the file management and retrieving of the backup
     case File.read "local_backup" do
       {:ok, complete_system} -> {:ok, :erlang.binary_to_term(complete_system)}
       {:error, :enoent} -> :unspecified
     end
  end

  def set_state(init_status, pid_FSM, pid_driver) do
    #TO DO: Complete the status management when backup is avalible
    if init_status == :unspecified do
      #Go to floor 0
      IO.puts "We are in unspecified with state #{inspect ElevatorFSM.get_state(pid_FSM)}"
      ElevatorFSM.set_status(pid_FSM, :IDLE,0,:stopped)
      Driver.set_motor_direction(pid_driver, :down)
      stop_initial(pid_driver)
      Driver.set_motor_direction(pid_driver, :stop)
      IO.puts "Elevator set to initial position #{inspect ElevatorFSM.get_state(pid_FSM)}"
    end
  end

  def stop_initial(pid_driver) do
    if Driver.get_floor_sensor_state(pid_driver) != 0 do
      stop_initial(pid_driver)
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

  def open_doors(pid_driver) do
    Driver.set_door_open_light(pid_driver, :on)
    :timer.sleep(3000);
    Driver.set_door_open_light(pid_driver, :off)
  end

  # def send_distributor_status(pid_distributor, pid_FSM) do
  #   #==========================================================================
  #   # TO DO: Send the status of elevator FSM and button pushes to distributor
  #   #IO.puts "Sending status to distributor"
  #   send pid_distributor {:orders}
  # end

  def store_local_backup(complete_system) do
    # @doc """
    #   This function stores the status of the complete system usinf the file
    #   library
    # """
    {:ok, file} = File.open("local_backup", [:write])
    IO.binwrite(file,:erlang.term_to_binary(complete_system))
    File.close(file)
  end

  def get_my_local_ip do
    case :inet.getif() do
        {:ok, [{ip, _defini1, _mask1}, {_nope, _defini, _mask2}]} ->
            ip
        {:ok, [_none1, {ip, _none2, _none3}, _none4]} ->
            ip
    end

  end

  def pid(string) when is_binary(string) do
    :erlang.list_to_pid('<#{string}>')
  end


  def order_collector(pid_driver, pid_distributor) do
    order_collector(pid_driver, pid_distributor,[],[],[])
  end

  def order_collector(pid_driver, pid_distributor, previous_cabs, previous_up, previous_down) do

    cabs = Enum.filter(@bottom_floor..@top_floor, fn x -> Driver.get_order_button_state(pid_driver,x,:cab) == 1 end)
    if cabs != [] do
      send_buttons(pid_distributor, :cab, cabs, previous_cabs)
    end
    hall_up = Enum.filter(@bottom_floor..@top_floor, fn x -> Driver.get_order_button_state(pid_driver,x,:hall_up) == 1 end)
    if hall_up != [] do
      send_buttons(pid_distributor, :hall_up, hall_up, previous_up)
    end
    hall_down = Enum.filter(@bottom_floor..@top_floor, fn x -> Driver.get_order_button_state(pid_driver,x,:hall_down) == 1 end)
    if hall_down != [] do
      send_buttons(pid_distributor, :hall_down, hall_down, previous_down)
    end
    order_collector(pid_driver, pid_distributor, cabs, hall_up, hall_down)
  end
  def send_buttons(pid_distributor, button_type, floors, previous) do
    if length(floors) == 1 and floors != previous do
      Enum.map(floors, fn x -> send pid_distributor, {:order, self(),Order.init(button_type, x)} end )
    end
  end

  def test_collector() do
    {:ok, pid_driver} = Driver.start()
    pid_distributor = self()
    spawn fn -> order_collector(pid_driver,pid_distributor) end
    test_collector(pid_driver)
  end

  def test_collector(pid_driver) do
    receive do
      {:order, pid_elevator,order} -> IO.puts("Received message: #{inspect(order)}")

    end

    test_collector(pid_driver)
  end


end
