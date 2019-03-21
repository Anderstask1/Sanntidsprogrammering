defmodule PhoenixCounter do
    @moduledoc """
    Documentation for PHOENIX_COUNTER.
    """

    @doc """
    Hello world.

    ## Examples

        iex> PHOENIX_COUNTER.hello()
        :world

    """
  def process_pairs() do
    pid_backup = spawn(fn->  backup_mode(0) end)
    pid_primary = spawn(fn->  primary_mode(pid_backup, 0) end)
    IO.puts "Primary PID is_ "
    IO.inspect pid_primary
  end

  def backup_mode(last_counter) do
    receive do
      {:ImAlive, _pid}->
        :ok
        #ImAlive_time = elem(:calendar.local_time(),1) %get seconds of actual date
      {:checkpoint, counter_check} ->
        backup_mode(counter_check)
      {_pid_self,:ImPrimary}  ->
        :ok
      after
        2_000 ->
          pid_backup = spawn(fn->   backup_mode(last_counter) end)
          send(pid_backup,{self(),:ImPrimary})#This is supponsed to be a broadcast! ->HELP<-
          primary_mode(pid_backup,last_counter)
    end
    backup_mode(last_counter)
  end

  def primary_mode(pid_backup, counter) do
    send(pid_backup,{:ImAlive, self()})
    send(pid_backup,{:checkpoint, counter})
    :timer.sleep(1000)
    IO.puts "I am process"
    IO.inspect self()
    IO.puts", the count is #{counter}"
    primary_mode(pid_backup, counter+1)
  end

end
