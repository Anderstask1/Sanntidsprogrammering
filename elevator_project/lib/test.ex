defmodule Test do
  def version01 do
    pid_spawned_elevator = spawn fn -> Elevatorm.start_working() end
    IO.puts "PID ELEV #{inspect pid_spawned_elevator}"

    IO.puts "PID DIST #{inspect pid_spawned_distributor}"
  end
end
