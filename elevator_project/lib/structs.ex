defmodule  Order do
  defstruct [:type, :floor, :cost]
end

defmodule State do
  defstruct [:direction, :floor]
end

defmodule Lights do
  defstruct []
end

defmodule Elevator do
  defstruct [:state, :orders, :lights]
end

# We can use alias to shorten the path
# iex -> alias complete_list[:ip1].state
# iex -> state.floor
# 1
