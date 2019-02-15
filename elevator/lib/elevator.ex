defmodule Elevator do
  #use GenServer
  #JMPT: I suggest using GenServer(Elixir Generic server) for the state machine


  @moduledoc """
  This is the beginning of our project.
  The actual code only moves the elevator up  and down.
  JMPT
  """

  @doc """
  Documentation of the elvator project

  ## Examples

      iex> Elevator.simple_ele()
      :world

  """
  IO.puts "This only runs doring compilation..."

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



  def hello do
    IO.puts "Hello brothres"
    :world
  end

def simple_ele() do
  {:ok, driver_pid}=Driver.start() #setup the elevator driver
  if Driver.set_floor_indicator(driver_pid, 2) == :between_floors do
    IO.puts "The cab is between floors"
  end
  Driver.set_motor_direction(driver_pid, :down)# Elevator go down!

  until_reach_floor(driver_pid, 0)
  IO.puts "Elevator is in floor 0"
  Driver.set_motor_direction(driver_pid, :up)# Elevator go up!

  until_reach_floor(driver_pid, 3)
  IO.puts "Elevator is in floor 3"
  Driver.set_motor_direction(driver_pid, :down)# Elevator go down!

  until_reach_floor(driver_pid, 0)
  IO.puts "Elevator is in floor 0"

  Driver.stop(driver_pid)# Stops the connection with the Elevator server
  # Driver.set_motor_direction(driver_pid, :stop) can be used instead for
  # stopping the elevator whiout disconnecting with the server

end


def until_reach_floor(driver_pid, floor) do
  #Blocks the code execution until the floor is changed to the value of floor
  if floor != Driver.get_floor_sensor_state(driver_pid) do
    until_reach_floor(driver_pid, floor)
  else
    :ok
  end
end



def server(name) do
  #To run this function:
  #   iex -S mix
  #   iex(2)> server_1=spawn(fn -> Elevator.server("server_1") end)
  #   send(server_1, "here the message") // This is the testing
    receive do #Wait here until I receive something :D
      message -> IO.puts "Server #{name} received #{message}"
    end
    Elevator.server(name)
  end

end
