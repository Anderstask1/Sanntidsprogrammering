defmodule Elevator do
  @moduledoc """
  Documentation for Elevator.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Elevator.hello()
      :world

  """
  IO.puts "This only runs doring compilation...."
  def hello do
    IO.puts "Hello brothres"
    :world
  end

def simple_ele() do
  {:ok, driver_pid}=Driver.start() #setup the elevator driver
  if Driver.set_floor_indicator(driver_pid, 2) == :between_floors do
    IO.puts "The cab is between floors"
  end
  Driver.set_motor_direction(driver_pid, :down)

  until_reach_floor(driver_pid, 0)
  IO.puts "Elevator is in floor 0"
  Driver.set_motor_direction(driver_pid, :up)# :up or :down

  until_reach_floor(driver_pid, 3)
  IO.puts "Elevator is in floor 3"
  Driver.set_motor_direction(driver_pid, :down)# :up or :down

  until_reach_floor(driver_pid, 0)
  IO.puts "Elevator is in floor 0"
  Driver.stop(driver_pid)

end

def until_reach_floor(driver_pid, floor) do
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
