defmodule ElevatorFSM do
  use GenServer



def test do
    {:ok,server_pid}=start_link
    {driver_pid,status,current_floor,next_floor,list}=ElevatorFSM.get_state(server_pid)
    IO.inspect ElevatorFSM.get_state(server_pid)
    :timer.sleep(1000)
    pid_updater = spawn fn -> floor_updater(server_pid,driver_pid, current_floor) end

    IO.inspect ElevatorFSM.get_state(server_pid)
    :timer.sleep(1000)
    IO.inspect ElevatorFSM.get_state(server_pid)

    go_to_floor(server_pid, 3)
end


  def start_link do
    {:ok, driver_pid}=Driver.start() #setup the elevator driver
    GenServer.start_link(ElevatorFSM, {driver_pid,:IDLE,:unknow,85,[0,3,1]})
  end

  def init(initial_data) do #set the initial state
    IO.puts "Driver inizialized with Pid: #{inspect elem(initial_data,0)}"
    {:ok, initial_data}
  end

  def floor_updater(server_pid,driver_pid, floor) do
      :timer.sleep(250)
      if Driver.set_floor_indicator(driver_pid,2)==:between_floors do
          new_floor = :between_floors
      else
      new_floor = Driver.get_floor_sensor_state(driver_pid)
    end
    if new_floor != floor do
        IO.puts "The lift is in a new floor: #{inspect new_floor}"
        GenServer.cast(server_pid, {:new_floor, floor})
        floor_updater(server_pid,driver_pid, new_floor)
    else
        floor_updater(server_pid,driver_pid, floor)
    end
  end




  def get_state(server_pid) do
      GenServer.call(server_pid, :get_state)
    end


  def go_to_floor(server_pid, floor) do
      GenServer.cast(server_pid, {:go_to_floor, floor})
  end


#========== CAST AND CALLS ==========================

  def handle_cast({:new_floor, floor}, state) do
    new_state=:erlang.setelement(3, state, floor)
     {:noreply, new_state}
  end





  def handle_cast({:go_to_floor, floor}, state) do
    driver_pid=elem(state,0)
    current_floor=elem(state,2)
    if current_floor == :between_floors do
        Driver.set_motor_direction(driver_pid, :up)
        handle_cast({:go_to_floor, floor},  state)
    end
    if current_floor > floor do
        Driver.set_motor_direction(driver_pid, :down)
        handle_cast({:go_to_floor, floor}, state)
    end
    if current_floor < floor do
        Driver.set_motor_direction(driver_pid, :up)
        handle_cast({:go_to_floor, floor}, state)
    end
    if current_floor == floor do
        Driver.set_motor_direction(driver_pid, :stop)
        {:noreply, state}
    end

    handle_cast({:go_to_floor, floor}, state)



  end


  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end








  # def handle_call(:update_floor, _from, my_state) do
  #   driver_pid=elem(my_state,0);
  #   floor=Driver.get_floor_sensor_state(driver_pid)
  #   new_state=:erlang.setelement(3, my_state, floor)
  #   {:reply, my_state, new_state}
  # end
  #
  # # def handle_call(:receive_orders, _from, my_state) do
  # #   receive do
  # #     {:order_list, list}  -> list
  # #   end
  # #   {:reply, my_state, :erlang.setelement(4, my_state, list)}
  # # end
  #
  # def handle_call(:work, _from, my_state) do
  #   driver_pid=elem(my_state,0)
  #   floor=elem(my_state,2)
  #   order_list=elem(my_state,3)
  #   if  order_list == nil do
  #     IO.puts "All work is done"
  #     {:reply, my_state, my_state}
  #   else
  #     if floor == List.first(order_list) do
  #       IO.puts "I am at that floor"
  #       new_list=List.delete_at(order_list,0)
  #       {:reply, my_state, {driver_pid,:WORKDONE, floor,new_list}}
  #     end
  #     if floor > List.first(order_list) do
  #       Driver.set_motor_direction(driver_pid, :up)
  #       until_reach_floor(driver_pid, floor)
  #       Driver.set_motor_direction(driver_pid, :stop)
  #       Driver.set_door_open_light(driver_pid, :on)
  #       :timer.sleep(1000);
  #       Driver.set_door_open_light(driver_pid, :off)
  #     else
  #       Driver.set_motor_direction(driver_pid, :down)
  #       until_reach_floor(driver_pid, floor)
  #       Driver.set_motor_direction(driver_pid, :stop)
  #       Driver.set_door_open_light(driver_pid, :on)
  #       :timer.sleep(1000);
  #       Driver.set_door_open_light(driver_pid, :off)
  #     end
  #
  #
  #     new_floor=List.first(order_list)
  #     new_list=List.delete_at(order_list,0)
  #     {:reply, my_state,{driver_pid,:WORKDONE, new_floor,new_list}}
  #   end
  # end
  #
  # def until_reach_floor(driver_pid, floor) do
  #   #Blocks the code execution until the floor is changed to the value of floor
  #   if floor != Driver.get_floor_sensor_state(driver_pid) do
  #     until_reach_floor(driver_pid, floor)
  #   else
  #     :ok
  #   end
  # end

end
