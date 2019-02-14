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
