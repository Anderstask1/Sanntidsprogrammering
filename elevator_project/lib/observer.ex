defmodule Observer do
  @moduledoc """
  This is the observer module. The observer is doing the udp-broadcast,
  adding new nodes to the clustera and keeping track of all active/alive nodes
  """

  @doc """
  this function says hello
  """
  def hello do
    IO.puts("Hello brothers")
    :world
  end
end
