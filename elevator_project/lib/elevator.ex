defmodule Elevatorm do
  # JMPT: I suggest using GenServer(Elixir Generic server) for the state machine

  @moduledoc """
  This is the elevator module. The elevator module controls one single elevator,
  handles internal orders and sends orders and states to distributor. The elevator
  acts like a slave and complete orders from master.
  """

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
  end

  @doc """
  check if floor is reached by elevator
  """
  def until_reach_floor(driver_pid, floor) do
    # Blocks the code execution until the floor is changed to the value of floor
    if floor != Driver.get_floor_sensor_state(driver_pid) do
      until_reach_floor(driver_pid, floor)
    else
      :ok
    end
  end

  @doc """
  simple server
  """
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
  end
end
