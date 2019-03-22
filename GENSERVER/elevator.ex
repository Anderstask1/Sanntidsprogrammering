defmodule Elevator do
  @moduledoc """
  This is the Elevator module
  """


  def start_working do
    {:ok, pid_driver} = Driver.start()       #setup driver connection
    {:ok,  pid_FSM  } = ElevatorFSM.start_link()  #connect_FSM()
    init_status=retrieve_local_backup()
    if Driver.get_floor_sensor_state(pid_driver) != 0 and init_status ==:unspecified do
      set_state(init_status, pid_FSM, pid_driver)
    else
      ElevatorFSM.set_status(pid_FSM, :IDLE,0,:stopped)
    end
    IO.puts "Calling loop"
    elevator_loop(pid_FSM, pid_driver, [3,1,0,2,0])
  end

  def elevator_loop(pid_FSM, pid_driver, list_of_orders) do
    list_of_orders = get_orders()  #receive the orders from the distributor
    if list_of_orders != [] do
      order = List.first(list_of_orders)
      ElevatorFSM.new_order(pid_FSM, pid_driver, order)

      {_state,current_floor,_movement} = ElevatorFSM.get_state(pid_FSM)
      if current_floor == order do

        ElevatorFSM.arrived(pid_FSM, pid_driver)
        open_doors(pid_driver)
        ElevatorFSM.continue_working(pid_FSM)
        send_distributor_status(pid_driver)
        :timer.sleep(100);
        elevator_loop(pid_FSM, pid_driver, List.delete_at(list_of_orders,0))

      else

        ElevatorFSM.new_order(pid_FSM, pid_driver, order)

      end
      ElevatorFSM.update_floor(pid_FSM, pid_driver)
      send_distributor_status(pid_driver)
    else
      IO.puts "All orders completed, state: #{inspect ElevatorFSM.get_state(pid_FSM)}"

    end
    :timer.sleep(100);
    elevator_loop(pid_FSM, pid_driver, list_of_orders)
  end


###############################################################################
###############################################################################
###############################################################################
  def retrieve_local_backup()  do
    #TO DO: Complete the file management and retrieving of the backup
    :unspecified
  end

  def set_state(init_status, pid_FSM, pid_driver) do
    #TO DO: Complete the status management when backup is avalible
    if init_status == :unspecified do
      #Go to floor 0
      Driver.set_motor_direction(pid_driver, :down)
      stop_initial(pid_driver)
      Driver.set_motor_direction(pid_driver, :stop)
      ElevatorFSM.update_floor(pid_FSM, pid_driver)
      ElevatorFSM.update_movement(pid_FSM, :stopped)
      IO.puts "Elevator set to initial position #{inspect ElevatorFSM.get_state(pid_FSM)}"
    end
  end

  def stop_initial(pid_driver) do
    if Driver.get_floor_sensor_state(pid_driver) != 0 do
      stop_initial(pid_driver)
    end
  end

  def get_orders(list) do
    #==========================================================================
    # TO DO: Handle the receive from the distributor keeping the complete
    # list of orders

    get_orders(List.delete_at(list, 0))
  end

  def open_doors(pid_driver) do
    Driver.set_door_open_light(pid_driver, :on)
    :timer.sleep(7000);
    Driver.set_door_open_light(pid_driver, :off)
  end

  def send_distributor_status(_pid_driver) do
    #==========================================================================
    # TO DO: Send the status of elevator FSM and buttom pushes to distributor
    IO.puts "Sending status to distributor"
  end

end
