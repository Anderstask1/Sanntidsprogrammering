defmodule DistributorTest do
  use ExUnit.Case
  doctest Distributor

  test "distributor module test" do
    pid_spawned_elevator = spawn(fn -> Elevatorm.start_working() end)
    IO.puts("PID ELEV #{inspect(pid_spawned_elevator)}")

    pid_spawned_distributor = spawn(fn -> Distributor.start([pid_spawned_elevator]) end)
    IO.puts("PID DIST #{inspect(pid_spawned_distributor)}")

    # ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    #
    # # Create list of orders
    # order1 = O# ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    # # ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    #
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # o# ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    # # ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    #
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = Sta# ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    # # ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    #
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # o# ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    # # ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    #
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)# ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    # # ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    #
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # o# ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    # # ############ Init list #################
    #
    # # Create state
    # state1 = State.init(:up, 0)
    #
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    # rder2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    # rder2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()te.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()
    # # Create list of orders
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    # rder2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()rder.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders1 = [order1, order2, order3, order4, order5]
    #
    # # Create list of lights
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_up, 2, :on)
    # lights1 = [light1, light2, light3]
    #
    # # Create elevator with ip and pid
    # ip1 = {10, 100, 23, 151}
    # pid1 = Pid.init(0, 109, 0)
    # elevator1 = Elevator.init(ip1, pid1, state1, orders1, lights1)
    #
    # # Create another elevator with different parameters
    # state2 = State.init(:up, 2)
    #
    # order1 = Order.init(:cab, 1)
    # order2 = Order.init(:cab, 2)
    # order3 = Order.init(:hall_down, 3)
    # order4 = Order.init(:hall_up, 2)
    # order5 = Order.init(:hall_down, 2)
    # orders2 = [order1, order2, order3, order4, order5]
    #
    # light1 = Light.init(:cab, 1, :on)
    # light2 = Light.init(:cab, 2, :on)
    # light3 = Light.init(:hall_down, 3, :on)
    # lights2 = [light1, light2, light3]
    #
    # ip2 = {10, 101, 23, 150}
    # pid2 = Pid.init(0, 110, 0)
    #
    # elevator2 = Elevator.init(ip2, pid2, state2, orders2, lights2)
    #
    # # Create complete list with the elevators
    # CompleteSystem.init(elevator1, elevator2)
    #
    # ################# Init distributor #################
    # #{:ok, pid_genserver} = Distributor.init()
  end
end
