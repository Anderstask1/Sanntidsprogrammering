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
  use Application

  def hello() do
    IO.puts "Hello"
  end
end
