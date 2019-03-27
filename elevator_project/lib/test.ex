defmodule Test do
  def version01 do
    pid_spawned_elevator = spawn(fn -> Elevatorm.start_working() end)
    IO.puts("PID ELEV #{inspect(pid_spawned_elevator)}")

<<<<<<< HEAD
    pid_spawned_distributor = spawn fn -> Distributor.start([{Elevatorm.get_my_local_ip, pid_spawned_elevator}]) end
    IO.puts "PID DIST #{inspect pid_spawned_distributor}"
=======
    pid_spawned_distributor =
      spawn(fn -> Distributor.start([{Elevatorm.get_my_local_ip(), pid_spawned_elevator}]) end)

    IO.puts("PID DIST #{inspect(pid_spawned_distributor)}")
>>>>>>> a731cbf498f183bc0fecbd0a761b65e3b483c26a
  end
end
