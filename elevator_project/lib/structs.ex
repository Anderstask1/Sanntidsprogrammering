defmodule  Order do
  @moduledoc """
  This is the order struct. Contains all orders with a type, a floor and a cost of the order
  """
  @bottom_floor 0
  @top_floor 3
  @valid_floor Enum.to_list @bottom_floor..@top_floor
  @valid_type [:cab, :hall_down, :hall_up]

  defstruct [:type, :floor, :cost]

  def valid do
    {@valid_type, @valid_floor}
  end

  def init(type, floor) when type in @valid_type and floor in  @valid_floor do
    %Order{type: type, floor: floor, cost: 0}
  end
end

defmodule State do
  @moduledoc """
  This is the state struct. Contains the state of the elevator with a floor and a direction
  """
  @bottom_floor 0
  @top_floor 3
  @valid_floor Enum.to_list @bottom_floor..@top_floor
  @valid_direction [:idle, :down, :up]

  defstruct [:direction, :floor]

  def valid do
    {@valid_direction, @valid_floor}
  end

  def init(direction, floor) do
    %State{direction: direction, floor: floor}
  end
end

defmodule Light do
  @moduledoc """
  This is the ligths struct. Contains which lights should be turned on
  """
  @bottom_floor 0
  @top_floor 3
  @valid_floor Enum.to_list @bottom_floor..@top_floor
  @valid_type [:cab, :hall_down, :hall_up]
  @valid_state [:on, :off]

  defstruct [:type, :floor, :state]

  def valid do
    {@valid_floor, @valid_type, @valid_state}
  end

  def init(type, floor, state) do
    %Light{type: type, floor: floor, state: state}
  end
end

defmodule Elevator do
  @bottom_floor 0
  @top_floor 3
  @valid_floor Enum.to_list @bottom_floor..@top_floor

  defstruct [:state, :orders, :lights]

  def valid do
    @valid_floor
  end

  def init(state = %State{}, orders, lights) do
    %Elevator{state: state, orders: orders, lights: lights}
  end
end

defmodule CompleteSystem do
  def init(ip1, elevator1, ip2, elevator2) do
    [{ip1, elevator1},{ip2, elevator2}]
  end

  def add_elevator(complete_list, ip1, elevator1) do
    [complete_list | {ip1, elevator1}]
  end
end

defmodule CreateList do

  def init_state do
    State.init(:up, 0)
  end

  def init_order do
    Order.init(:hall_down, 3)
  end

  def init_orders do
    order1 = Order.init(:cab, 1)
    order2 = Order.init(:cab, 2)
    order3 = Order.init(:hall_down, 3)
    order4 = Order.init(:hall_up, 2)
    order5 = Order.init(:hall_down, 2)
    [order1, order2, order3, order4, order5]
  end

  def init_lights do
    light1 = Light.init(:cab, 1, :on)
    light2 = Light.init(:cab, 2, :on)
    light3 = Light.init(:hall_up, 2, :on)
    [light1, light2, light3]
  end

  def init_elevator do
    state = State.init(:up, 0)

    order1 = Order.init(:cab, 1)
    order2 = Order.init(:cab, 2)
    order3 = Order.init(:hall_down, 3)
    order4 = Order.init(:hall_up, 2)
    order5 = Order.init(:hall_down, 2)
    orders = [order1, order2, order3, order4, order5]

    light1 = Light.init(:cab, 1, :on)
    light2 = Light.init(:cab, 2, :on)
    light3 = Light.init(:hall_up, 2, :on)
    lights = [light1, light2, light3]

    Elevator.init(state, orders, lights)
  end

  def init_list do
    state = State.init(:up, 0)

    order1 = Order.init(:cab, 1)
    order2 = Order.init(:cab, 2)
    order3 = Order.init(:hall_down, 3)
    order4 = Order.init(:hall_up, 2)
    order5 = Order.init(:hall_down, 2)
    orders = [order1, order2, order3, order4, order5]

    light1 = Light.init(:cab, 1, :on)
    light2 = Light.init(:cab, 2, :on)
    light3 = Light.init(:hall_up, 2, :on)
    lights = [light1, light2, light3]

    elevator1 = Elevator.init(state, orders, lights)

    state = State.init(:up, 2)

    order1 = Order.init(:cab, 1)
    order2 = Order.init(:cab, 2)
    order3 = Order.init(:hall_down, 3)
    order4 = Order.init(:hall_up, 2)
    order5 = Order.init(:hall_down, 2)
    orders = [order1, order2, order3, order4, order5]

    light1 = Light.init(:cab, 1, :on)
    light2 = Light.init(:cab, 2, :on)
    light3 = Light.init(:hall_down, 3, :on)
    lights = [light1, light2, light3]

    elevator2 = Elevator.init(state, orders, lights)
    ip1 = {10, 100, 23, 151}
    ip2 = {10, 101, 23, 150}
    complete_list = [{ip1, elevator1},{ip2, elevator2}]
    Enum.sort(complete_list)
  end
end

# We can use alias to shorten the path
# iex -> alias complete_list[:ip1].state
# iex -> state.floor
# 1
