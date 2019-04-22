defmodule Distributor do
  @moduledoc """
  The distributor is a part of the master, doing the computation of shortest-path and cost function,
  in order to distribute elevator orders. The distribitur in all nodes recieves the list of orders
  and states, but only the master distribitur distribute.
  """
  use GenServer
  @bottom 0
  @top 3

  @doc """
  Input is a list of tuples with the ip of each node in the cluster.
  Setup the genserver, create a list of elevators with the ip in the input
  and broadcast this list to all nodes.
  """

  # create the genserver with an empty list
  def start() do
    {:ok, pid_genserver} = start_server(Enum.map(Utilities.all_nodes, fn ip -> Elevator.init(ip) end))
    IO.puts("DIST start pid: #{inspect(self())}")
    IO.puts("Pid dist genserver: #{inspect(pid_genserver)}")
    {:ok, ip_watchdog} = WatchdogList.start()
    IO.puts("ip watchdog: #{inspect(ip_watchdog)}")
    Enum.map(Utilities.all_nodes, fn ip -> WatchdogList.add_to_watchdog_list(ip) end)
  end

  # =========== GENSERVER =============
  # -------------API -----------------

  def init(list) do
    {:ok, list}
  end

  def start_server(complete_list) do
    GenServer.start_link(__MODULE__, complete_list, name: :genserver)
  end

  def get_complete_list do
    GenServer.call(:genserver, :get_complete_list)
  end

  def send_order(order, ip) do
    GenServer.multi_call(Utilities.all_nodes, :genserver, {:send_order, order, ip})
  end

  def send_state(state, ip) do
    GenServer.multi_call(Utilities.all_nodes, :genserver, {:send_state, state, ip})
  end

  def send_lights(lights, ip) do
    GenServer.multi_call(Utilities.all_nodes, :genserver, {:send_lights, lights, ip})
  end

  def add_to_complete_list(elevator, ip) do
    GenServer.multi_call(Utilities.all_nodes, :genserver, {:add_to_complete_list, elevator, ip})
  end

  def delete_from_complete_list(elevator_ip) do
    GenServer.cast(:genserver, {:delete_from_complete_list, elevator_ip})
  end

  def update_list(new_list) do
    GenServer.cast(:genserver, {:update_list, new_list})
  end

  # -------------CAST AND CALLS -----------------

  def handle_call(:get_complete_list, _from, complete_list) do
    #IO.puts("........complete_list #{inspect complete_list}")
    {:reply, complete_list, complete_list}
  end



  def handle_call({:send_order, order, ip}, from, complete_list) do
      IO.puts("The reveived order is from ip#{inspect ip}")
      IO.puts("Handle milticall send order from --- #{inspect from}")
      kill_broken_elevators(complete_list)
      if get_elevator_in_complete_list(ip, complete_list) != nil do
          updated = update_system_list(ip, order, complete_list)
          IO.puts("The updated list with the new order is")
          print_list(updated)
          {:reply, :ok, updated}
      else
          IO.puts "Trying to update the orders of an elevator that is not in the system yet"
          {:reply, :ok, complete_list}
      end
  end

  def handle_call({:send_state, state, ip}, _from, complete_list) do
    kill_broken_elevators(complete_list)
    if get_elevator_in_complete_list(ip, complete_list) != nil do
        {:reply, :ok, update_system_list(ip, state, complete_list)}
    else
        IO.puts "Trying to update the state of an elevator that is not in the system yet"
        {:reply, :ok, complete_list}
    end
  end

  def handle_call({:send_lights, lights, ip}, _from, complete_list) do
      if get_elevator_in_complete_list(ip, complete_list) != nil do
          if get_elevator_in_complete_list(ip, complete_list).lights == lights do
              {:reply, :ok, complete_list}
          else
              {:reply, :ok, update_system_list(ip, lights, complete_list)}
          end
      else
          IO.puts "Trying to update the lights of an elevator that is not in the system yet"
          {:reply, :ok, complete_list}
      end
  end

  def handle_call({:add_to_complete_list, elevator, ip}, _from, complete_list) do
    IO.puts("New node in cluster the complete list now is")
    print_list(complete_list)
    case {Enum.member?(Enum.map(complete_list, fn list_elevator -> list_elevator.ip end), elevator.ip), elevator.state != nil} do
      {true, true} ->
        IO.puts("TRUE")
        replaced_list = replace_elevator_in_complete_list(elevator, elevator.ip, complete_list)
        sorted_list = Enum.sort_by(replaced_list, fn d -> d.ip end)
        {:reply, :ok, sorted_list}
      {false, true} ->
        IO.puts("FALSE1")
        new_list=complete_list ++ [elevator]
        sorted_list = Enum.sort_by(new_list, fn d -> d.ip end)
        {:reply, :ok, sorted_list}
      _ ->
        IO.puts("FALSE2")
        {:reply, :ok, complete_list}
    end
  end

  def handle_cast({:delete_from_complete_list, elevator_ip}, complete_list) do
    IO.puts("Delete elevator from list with name #{inspect elevator_ip}")
    {:noreply, List.delete(complete_list, get_elevator_in_complete_list(elevator_ip, complete_list))}
  end

  def handle_cast({:update_list, new_list}, _complete_list) do
    {:noreply, new_list}
  end

  def delete_elevator_in_complete_list(elevator, complete_list) do
    List.delete(complete_list, elevator)
  end

  def get_elevator_in_complete_list(ip, complete_list) do
    Enum.find(complete_list, fn elevator -> elevator.ip == ip end)
  end

  def replace_elevator_in_complete_list(new_elevator, ip, complete_list) do
    index = Enum.find_index(complete_list, fn elevator -> elevator.ip == ip end)
    List.replace_at(complete_list, index, new_elevator)
  end

  ############# HANDLE BAD NODES
  # def multi_call_reply_handling(reply) when reply != nil do
  #   elem(reply, 1) |>
  #   Enum.each(fn bad_node ->
  #     broken_elevator = get_elevator_in_complete_list(NodeCollector.ip(bad_node), complete_list)
  #     delete_elevator_in_complete_list(broken_elevator, complete_list)
  #     redistribute_orders(broken_elevator, complete_list)
  #   end)
  #end

###### ================== CHANGE THIS TO IP
def kill_broken_elevators(complete_list) do
  if WatchdogList.is_elevator_broken() != nil do
      {ip, _} = WatchdogList.is_elevator_broken()
      IO.puts("kill node #{inspect(ip)}")
      broken_elevator = get_elevator_in_complete_list(ip, complete_list)
      %{broken_elevator | harakiri: true}
      |> replace_elevator_in_complete_list(ip, complete_list) # Hakiri: Japanese= cut your belly
      if length(complete_list) == 1 do
        IO.puts("Master say goodbye ;( ")
        Process.exit(self(), :kill)
      end
      new_list=delete_elevator_in_complete_list(broken_elevator, complete_list)
	  update_list(new_list)
	  Enum.each(broken_elevator.orders, fn order ->
        if order != :cab do
          update_system_list(List.first(new_list).ip, order, complete_list)
        end
      end)
  end
end


  @doc """
  Update state of elevator by ip. When receiving the state from an elevator module, the state in the stored
  list is updated and completed orders are deleted. An order is completed if the new state of the elevator is
  at the same floor as an existing order and has stopped. The light is set to Off if it was turned on earlier,
  or added to the light orders if not. The watchdog check if an elevator is using too long time to move between
  floors, and kill the node if that is the case
  """
  def update_system_list(sender_ip, state = %State{}, complete_list) do
    new_complete_list = Enum.map(complete_list, fn  elevator ->
        if elevator.lights != [] do
            new_lights = Enum.map(elevator.lights, fn  x ->
                if x.type != :cab and state.direction == :idle do
                    if state.floor == x.floor do
                        Light.init(x.type, x.floor, :off)
                    else
                      x
                    end
                else
                    x
                end
            end)
            Elevator.init(elevator.harakiri, elevator.ip,elevator.state, elevator.orders, new_lights)
        else
            elevator
        end
    end)



    elevator = get_elevator_in_complete_list(sender_ip, new_complete_list)
    temp =
      if elevator.orders != [] and elevator.orders != nil do
        if state.direction == :idle do
          new_lights = Enum.map(elevator.lights, fn  x -> update_light(state,x) end)
          WatchdogList.update_watchdog_list(elevator.ip)
          new_elevator_orders = Enum.filter(elevator.orders, fn x ->  x.floor != state.floor end)
          Elevator.init(elevator.harakiri, elevator.ip,state, new_elevator_orders, new_lights)
        else
          Elevator.init(elevator.harakiri, elevator.ip, state, elevator.orders, elevator.lights)
        end
        |> replace_elevator_in_complete_list(sender_ip, new_complete_list)
      else
        WatchdogList.update_watchdog_list(elevator.ip)
        Elevator.init(elevator.harakiri, elevator.ip, state, elevator.orders, elevator.lights)
        |> replace_elevator_in_complete_list(sender_ip, new_complete_list)
      end
    temp
  end

  @doc """
  Update orders and lights of elevators. When receiving an order from an elevator module, the order is
  distributed to the elevator with minimum cost and added to the bottom of the orders list. Lights is
  set to be turned on when an orders is distributed, eighter by changing the same light order to Off
  or adding it to light order list.
  """
  def update_system_list(sender_ip, order = %Order{}, complete_list) do
    elevator =
      if get_elevator_in_complete_list(sender_ip, complete_list) == nil do
        Elevator.init([])
      else
        get_elevator_in_complete_list(sender_ip, complete_list)
      end
    IO.puts("--- THIS elevator received an order #{inspect elevator}")
    new_light = Light.init(order.type, order.floor, :on)
    case order.type do
      :cab ->
        if Enum.any?(elevator.lights, fn light -> light.floor != new_light.floor and light.type != new_light.type end) or elevator.lights == [] do
          IO.puts("Cab order, elevator ---- #{inspect elevator.ip} ---- takes order ---- #{inspect order} ---- computed by --- #{inspect Node.self()}")
          new_lights = change_state_light_in_list(elevator, new_light)
          WatchdogList.update_watchdog_list(elevator.ip)
          %{elevator | orders: elevator.orders ++ [order], lights: new_lights}
          |> replace_elevator_in_complete_list(elevator.ip, complete_list)
        end
      _ ->
        new_complete_list =
          Enum.map(complete_list, fn elevator_in_list ->
            new_lights = change_state_light_in_list(elevator_in_list, new_light)
            %{elevator_in_list | lights: new_lights}
          end)
		IO.puts("Computing cost of order #{inspect order} in the list  #{inspect new_complete_list}")
        elevator_min = compute_min_cost_all_elevators(order, new_complete_list)
        IO.puts("Outside order, elevator ---- #{inspect elevator_min.ip} ---- takes order ---- #{inspect order} ---- computed by --- #{inspect Node.self()}")
        WatchdogList.update_watchdog_list(elevator_min.ip)
        #======================================================================
        #=========SOMETHING IS WRONG HERE ===================
        #======================================================================
        %{elevator_min | orders: elevator_min.orders ++ [order]}
        |> replace_elevator_in_complete_list(elevator_min.ip, new_complete_list)
    end
  end

  @doc """
  Replace
  """
  def update_system_list(sender_ip, lights, complete_list) do
    elevator = get_elevator_in_complete_list(sender_ip, complete_list)
    %{elevator | lights: lights}
    |> replace_elevator_in_complete_list(sender_ip, complete_list)
  end

  def update_light(state, light) do
    if state.floor == light.floor and state.direction == :idle do
        %Light{light | state: :off}
    else
      light
    end
  end

  def change_state_light_in_list(elevator_in_list, new_light) do
    Enum.map(elevator_in_list.lights, fn light ->
      if light.floor == new_light.floor and light.type == new_light.type do
        new_light
      else
        light
      end
    end)
  end

  # ============== COST COMPUTATION ===================
  # @doc """
  # Converts the direction in atoms to an integer
  # """
  # def direction_to_integer(state) do
  #   case state.direction do
  #     :up -> 1
  #     :idle -> 0
  #     :down -> -1
  #     _ -> :error
  #   end
  # end
  #
  # @doc """
  # Check if the state of the elevator and an order is at the same floor and
  # moving in the same direction
  # """
  # def is_same_floor_same_direction(state, order) do
  #   case {state.direction, order.type} do
  #     {:down, :hall_down} -> state.floor == order.floor
  #     {:up, :hall_up} -> state.floor == order.floor
  #     _ -> false
  #   end
  # end
  #
  # @doc """
  # Simulate an elevator, computing number of steps from the state of the elevator to
  # the order. Fulfilled when state and order is the same floor and direction
  # """
  # def simulate_elevator(duration, state, order) do
  #   cond do
  #     is_same_floor_same_direction(state, order) ->
  #       duration
  #     true ->
  #       state =
  #         case {state.direction, state.floor} do
  #           {:up, @top} -> %State{state | direction: :down}
  #           {:down, @bottom} -> %State{state | direction: :up}
  #           _ -> %State{state | floor: state.floor + direction_to_integer(state)}
  #         end
  #       simulate_elevator(duration + 1, state, order)
  #   end
  # end
  #
  # @doc """
  # this function compute the cost for a single elevator. the order
  # """
  # def compute_cost_order(state, order) do
  #   case {state.direction, order.type} do
  #     {:idle, _} ->
  #       abs(state.floor - order.floor)
  #     _other ->
  #       simulate_elevator(0, state, order)
  #   end
  # end
  #
  # def compute_cost_all_orders(state, orders) do
  #   cost_list = []
  #   temp1 = Enum.map(orders, fn order -> %Order{order | cost: compute_cost_order(state, order)}end)
  #   temp2 =  Enum.map(temp1, fn order -> cost_list ++ order.cost end)
  #   temp3 =  Enum.sum(temp2)
  #   temp3
  # end
  #
  # def compute_min_cost_all_elevators(order, complete_list) do
  #   cost_list = Enum.map(complete_list, fn elevator -> compute_cost_all_orders(elevator.state, elevator.orders ++ [order]) end)
  #   IO.puts("Cost of different elevators is #{inspect cost_list}")
  #   min_cost = Enum.min(cost_list)
  #   index = Enum.find_index(cost_list, fn x -> x == min_cost end)
  #   Enum.at(complete_list, index)
  # end


  def compute_min_cost_all_elevators(order, complete_list) do
    cost_list = Enum.map(complete_list, fn elevator -> length(elevator.orders) + abs(elevator.state.floor - order.floor) end)
    IO.puts("Cost of different elevators is #{inspect cost_list}")
    min_cost = Enum.min(cost_list)
    index = Enum.find_index(cost_list, fn x -> x == min_cost end)
    Enum.at(complete_list, index)
  end

  def print_list(list) do
    IO.puts "<=========================================================================================>"
    IO.puts   "<=========== Complete list with #{inspect length(list)} elevator(s)======================>"
    Enum.map(list, fn ele ->
      IO.puts "<@@Elevator #{inspect ele.ip} with state #{inspect ele.state}"
      IO.puts "<======List of lights  with #{inspect length(ele.lights)} lights"
      #Enum.map(ele.lights, fn light -> IO.write "#{inspect light}||" end)
      IO.puts " "
      IO.puts "<======List of orders  with #{inspect length(ele.orders)} orders"
      Enum.map(ele.orders, fn order -> IO.puts "#{inspect order}" end)
    end)
      IO.puts "<=========================================================================================>"
  end

end

defmodule WatchdogList do
  @moduledoc """
  The watchdog is watching all elevators, checking if an elevator is using more than 5 seconds to move bewteen floors.
  """
  use GenServer

  # =========== GENSERVER =============
  # -------------API -----------------

  def init(list) do
    {:ok, list}
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: :watchdoglist)
  end

  def get_watchdog_list(ip) do
    GenServer.call(:watchdoglist, {:get_watchdog_list, ip})
  end

  def is_elevator_broken do
    GenServer.call(:watchdoglist, {:is_elevator_broken, Time.utc_now()})
  end

  def add_to_watchdog_list(ip) do
    GenServer.cast(:watchdoglist, {:add_to_watchdog_list, ip})
  end

  def update_watchdog_list(ip) do
    GenServer.cast(:watchdoglist, {:update_watchdog_list, ip})
  end

  # -------------CAST AND CALLS -----------------

  def handle_call({:get_watchdog_list, find_ip}, _from, watchdog_list) do
    IO.puts("Get watchdog list #{inspect(watchdog_list)} with ip #{inspect(find_ip)}")
    {:reply, Enum.find(watchdog_list, fn {ip, _} -> ip == find_ip end), watchdog_list}
  end

  def handle_call({:is_elevator_broken, new_time}, _from, watchdog_list) do
    {:reply, Enum.find(watchdog_list, fn {_, time} -> !(time == nil or Time.diff(new_time, time) < 25) end), watchdog_list}
  end

  def handle_cast({:add_to_watchdog_list, ip}, watchdog_list) do
    IO.puts("Add time to ip #{inspect(ip)} in watchdog_list #{inspect(watchdog_list)}")
    {:noreply, watchdog_list ++ [{ip, nil}]}
  end

  def handle_cast({:update_watchdog_list, find_ip}, watchdog_list) do
    watchdog = Enum.map(watchdog_list, fn {ip, time} ->
        if ip == find_ip do
          {find_ip, Time.utc_now()}
        else
          {ip, time}
        end
      end)
    {:noreply, watchdog}
  end
end
