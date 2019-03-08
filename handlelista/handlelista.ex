defmodule Handlelista do
use GenServer
  # What does the function take inn, what does it do and what can you expect to get as output
  @doc """
  returnerer :hello

  To call this in the terminal, just write
    h Distributor.holle
  """

  def loop lista do
    receive do

      {:legg_til, ting} ->
        loop [ting | lista]

      {:fjern, ting} ->
        loop List.delete(lista, ting)

      :skriv_ut ->
        lista |> Enum.each(fn ting -> IO.puts ting end)
        loop lista

    end
  end

  # User API
  def start do
    spawn fn -> loop([]) end
  end

  def legg_til handleliste, ting do
    handleliste |> send({:legg_til, ting})
  end

  def fjern handleliste, ting do
    handleliste |> send({:fjern, ting})
  end

  def skriv_ut handleliste do
    handleliste |> send(:skriv_ut)
  end

  # GenServer casts
  def handle_cast {:add_to_list, ting, list} socket do
    [ting | list]
  end

  def handle_cast {:remove_from_list, ting, list} socket do
    loop List.delete(list, ting)
  end

  # User API genserver
  def start_gen do
    spawn fn -> loop([]) end
  end

  def legg_til_gen pid , ting do
    GenServer.cast pid, {:add_to_list, ting, list}
  end

  def fjern_gen handleliste, ting do
    GenServer.cast pid, {:remove_from_list, ting, list}
  end

  def skriv_ut_gen handleliste do
    handleliste |> send(:skriv_ut)
  end

end
