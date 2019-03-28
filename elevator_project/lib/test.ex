defmodule Test do
  def version01 do
    pid_spawned_observer = spawn(fn -> Init.init() end)
    IO.puts("PID OBS #{inspect(pid_spawned_observer)}")

    pid_spawned_elevator = spawn(fn -> Elevatorm.start_working() end)
    IO.puts("PID ELEV #{inspect(pid_spawned_elevator)}")

    pid_spawned_distributor =
      spawn(fn -> Distributor.start([{Elevatorm.get_my_local_ip(), pid_spawned_elevator}]) end)

    IO.puts("PID DIST #{inspect(pid_spawned_distributor)}")

  end
end
