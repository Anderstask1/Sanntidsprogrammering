defmodule Updater do
  use GenServer

  def start_link do
    GenServer.start_link(ElevatorFSM, :listen)
  end

  def init(initial_data) do #set the initial state
    IO.puts "Driver inizialized with Pid: #{inspect elem(initial_data,0)}"
    {:ok, initial_data}
  end

  def get_current_floor(server_pid) do
      GenServer.call(server_pid, :get_state)
    end

  def update_floor(server_pid) do
      GenServer.call(server_pid, :update_floor)
    end


  def work(server_pid) do
      GenServer.call(server_pid, :work, 10000)
  end

  def go_to_floor(server_pid, floor) do
      GenServer.cast(server_pid, {:go_to_floor, floor})
  end

#========== CAST AND CALLS ==========================

def handle_cast({:push, item}, state) do
  {:noreply, [item | state]}
end
