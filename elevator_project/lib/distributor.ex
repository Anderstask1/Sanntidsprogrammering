defmodule Distributor do

  @moduledoc """
  This is the distribitur module. The distributor is a part of the master, doing the computation
  of shortest-path and cost function, in order to distribute elevator orders. The distribitur in all
  nodes recieves the list of orders and states, but only the master distribitur distribute. 
  """

  @doc """
  this function says hello
  """

  def hello do
    IO.puts "Hello brothers and sisters"
    :world
  end

  @doc """
  this function says hello
  """

  def holle do
    IO.puts "Hello brothers and sisters"
    :world
  end
end
