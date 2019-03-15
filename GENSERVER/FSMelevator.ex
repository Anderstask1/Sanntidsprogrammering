defmodule ElevatorFSM do
  use GenServer
  # This module implments a FSM with 4 states:
  #   :INITIALIZE
  #   :IDLE
  #   :MOVE
  #   :ARRIVED_FLOOR

  def start_link() do
    GenServer.start_link(ElevatorFSM, :INITIALIZE)
    end

  def init(initial_data) do #set the initial state
    {:ok, pid_driver} = Driver.start() #setup the elevator driver
    go_to_known_floor(pid_driver)
    {:ok, {initial_data, pid_driver, 0, :stopped}}
    end

  def get_state(server_pid) do
      GenServer.call(server_pid, :get_state)
  end

  def valid_floor(server_pid) do
        GenServer.cast(server_pid, :valid_floor)
  end

  def next_order(server_pid, order) do
      GenServer.call(server_pid, {:next_order, order})
  end

  def arrived(server_pid) do
      GenServer.call(server_pid, :arrived)
  end

  def continue(server_pid) do
      GenServer.cast(server_pid, :continue)
  end

  def next_order_current(server_pid) do
      GenServer.cast(server_pid, :next_order_current)
  end


  def elevator(list_of_orders, pid_FSM) do
      {state, pid_driver, current_floor, movement}=get_state(pid_FSM)
      current_order = List.first(list_of_orders)
      current_floor = Driver.get_floor_sensor_state(pid_driver)

      if :INITIALIZE == elem(get_state(pid_FSM),0) do
        valid_floor(pid_FSM)
      end

      if current_order == nil do
          IO.puts "All work done"
          Timer.sleep(500)
          elevator(list_of_orders, pid_FSM)
      else
          if current_order == current_floor  do
              next_order_current(pid_FSM)
          else
              next_order(pid_FSM, current_order)
          end
          if elem(get_state(pid_FSM),2) == current_order do
            arrived(pid_FSM)
            continue(pid_FSM)
          end
          elevator(List.delete_at(list_of_orders,0),pid_FSM)
      end

    # def elevator_run do
    #   {:ok,pid_FSM} = ElevatorFSM.start_link()
    #   {state, pid_driver, current_floor, movement}=get_state(pid_FSM)
    #   pid_updater = spawn fn -> floor_updater(pid_FSM,pid_driver) end
    #   elevator([1,3,2,0,1,0],pid_FSM)
    # end


  end
  # def elevator(list_of_orders) do
  #     {:ok,pid_FSM} = ElevatorFSM.start_link
  #     {:ok, pid_driver} = Driver.start() #setup the elevator driver
  #     current_order = List.first(list_of_orders)
  #     current_floor = get_floor(pid_driver)
  #     if current_order == nil do
  #         valid_floor(pid_FSM)
  #         IO.puts "All work done"
  #     else
  #         if current_order <= 3 and current_floor >=0 do
  #             valid_floor(pid_FSM)
  #         end
  #         if current_order == current_floor  do
  #             next_order_current(pid_FSM)
  #         else
  #             move_to(current_floor, pid_driver)
  #         end
  #         next_order(pid_FSM)
  #         move_to(current_order,pid_driver)
  #         arrived(pid_FSM)
  #         continue(pid_FSM)
  #         elevator(List.delete_at(list_of_orders,0))
  #     end
  #
  # end

  # def move_to(floor , pid_driver) do
  #     current_floor = get_floor(pid_driver);
  #     if current_floor == :between_floors do
  #         Driver.set_motor_direction(pid_driver, :down)
  #         Timer.sleep(500)
  #         Driver.set_motor_direction(pid_driver, :stop)
  #     end
  #     current_floor = get_floor(pid_driver);
  #     if floor == current_floor do
  #         Driver.set_motor_direction(pid_driver, :stop)
  #     end
  #     if floor > current_floor do
  #         Driver.set_motor_direction(pid_driver, :up)
  #         move_to(floor , pid_driver)
  #     end
  #     if floor < current_floor do
  #         Driver.set_motor_direction(pid_driver, :down)
  #         move_to(floor , pid_driver)
  #     end
  # end
  #



  def floor_updater(server_pid,pid_driver) do
      floor = Driver.get_floor_sensor_state(pid_driver)
      floor_updater(server_pid,pid_driver,floor)
  end
  def floor_updater(server_pid, pid_driver, previous_floor) do
    new_floor = Driver.get_floor_sensor_state(pid_driver)
    if new_floor == :between_floors do
      floor_updater(server_pid, pid_driver, :between_floors)
    else
      if new_floor != previous_floor do
        IO.puts "The lift is in a new floor: #{inspect new_floor}"
        GenServer.cast(server_pid, {:new_floor, new_floor})
        floor_updater(server_pid,pid_driver, new_floor)
      else
        floor_updater(server_pid,pid_driver, new_floor)
      end
    end
  end





    def go_to_known_floor(pid_driver) do
      Driver.set_motor_direction(pid_driver, :down)
      arriving_control(pid_driver, 0)
      Driver.set_motor_direction(pid_driver, :stop)
    end

    def arriving_control(pid_driver ,objective_floor) do
      if Driver.get_floor_sensor_state(pid_driver) == objective_floor do
        IO.puts "Arrived!"
      else
        arriving_control(pid_driver ,objective_floor)
      end
    end



    #========== CAST AND CALLS ==========================
    def handle_cast(:valid_floor, state) do
        if elem(state,0) == :INITIALIZE do
            {:noreply, put_elem(state, 0, :IDLE)}
        else
            IO.puts "ERROR, unexpected status"
            {:noreply, :error}
        end
      end


    def handle_cast({:new_floor, floor }, state) do
            {:noreply, put_elem(state, 1, floor)}
      end

    def handle_cast({:next_order, destination}, {state, pid_driver, current_floor, movement}) do
    if state == :IDLE do
        if current_floor > destination do
          Driver.set_motor_direction(pid_driver, :down)
          {:noreply,{state, pid_driver, current_floor, :going_down}}
        else
          Driver.set_motor_direction(pid_driver, :up)
          {:noreply,{state, pid_driver, current_floor, :going_up}}
        end

    else
        IO.puts "ERROR, unexpected status"
        {:noreply, :error}
    end
      end



    def handle_cast(:continue, state) do
        if elem(state,0) == :ARRIVED_FLOOR do
            {:noreply, put_elem(state, 0, :IDLE)}
        else
            IO.puts "ERROR, unexpected status"
            {:noreply, :error}
        end
      end

    def handle_cast(:next_order_current, state) do
        if elem(state,0) == :IDLE do
            {:noreply, put_elem(state, 0, :ARRIVED_FLOOR)}
        else
            IO.puts "ERROR, unexpected status"
            {:noreply, :error}
        end
      end



    def handle_call(:get_state, _from, state) do
        {:reply, state, state}
      end

      def handle_call(:arrived, _from, {state, pid_driver, current_floor, movement}) do
          if state == :MOVE do
              Driver.set_door_open_light(pid_driver, :on)
              :timer.sleep(1000);
              Driver.set_door_open_light(pid_driver, :off)
              {:reply, {state, pid_driver, current_floor, movement}, {:ARRIVED_FLOOR, pid_driver, current_floor, :stopped}}
          else
              IO.puts "ERROR, unexpected status"
              {:reply, :error}
          end
        end

end
