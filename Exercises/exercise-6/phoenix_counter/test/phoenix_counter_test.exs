defmodule PHOENIX_COUNTERTest do
  use ExUnit.Case
  doctest PHOENIX_COUNTER

  test "greets the world" do
    assert PHOENIX_COUNTER.hello() == :world
  end
end
