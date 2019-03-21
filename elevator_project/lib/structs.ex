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
