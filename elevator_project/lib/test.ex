defmodule Test do
  def version01 do
    Init.init()

    pid_spawned_observer = spawn(fn -> Init.init() end)
    IO.puts("PID OBS #{inspect(pid_spawned_observer)}")

    :timer.sleep(1000)
	System.cmd("epmd -daemon", [])
	System.cmd("ElevatorServer", [])
    pid_spawned_elevator = spawn(fn -> Elevatorm.start() end)
    IO.puts("PID ELEV #{inspect(pid_spawned_elevator)}")

    pid_spawned_distributor = spawn(fn -> Distributor.start() end)

    IO.puts("PID DIST #{inspect(pid_spawned_distributor)}")
  end
end
