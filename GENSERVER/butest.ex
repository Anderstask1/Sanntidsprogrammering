defmodule Butest do
  @bottom_floor 0
  @top_floor 3
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
