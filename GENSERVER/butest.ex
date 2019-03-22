defmodule Butest do
  @bottom_floor 0
  @top_floor 3
  def order_collector(pid_driver, pid_distributor) do
    order_collector(pid_driver, pid_distributor,[],[],[])
  end

  def order_collector(pid_driver, pid_distributor, previous_cabs, previous_up, previous_down) do

    cabs = Enum.filter(0..3, fn x -> Driver.get_order_button_state(pid_driver,x,:cab) == 1 end)
    send_buttons(pid_distributor, :cab, cabs, previous_cabs)

    hall_up = Enum.filter(0..3, fn x -> Driver.get_order_button_state(pid_driver,x,:hall_up) == 1 end)
    send_buttons(pid_distributor, :hall_up, hall_up, previous_up)

    hall_down = Enum.filter(0..3, fn x -> Driver.get_order_button_state(pid_driver,x,:hall_down) == 1 end)
    send_buttons(pid_distributor, :hall_down, hall_down, previous_down)

    order_collector(pid_driver, pid_distributor, cabs, hall_up, previous_down)
  end
  def send_buttons(pid_distributor, button_type, floors, previous) do
    if floors != previous do
      IO.puts "Push in floor #{inspect(floors)} of the #{inspect(button_type)} type"

      Enum.map(floors, fn x -> send( pid_distributor,{:order, self(),Order.init(button_type, x)}) end )
    end
  end

  def test_collector() do
    {:ok, pid_driver} = Driver.start()
    spawn fn -> order_collector(pid_driver,self()) end
    IO.puts "Call to loop"
    test_collector(pid_driver)
  end

  def test_collector(_pid_driver) do
    receive do
      {:order, pid_elevator, order} ->
        IO.puts "Elevator has sent #{inspect({:order, pid_elevator, order})}"
    end
  end
end
