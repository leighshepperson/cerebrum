defmodule Cerebrum.Sensor do
  defstruct name: "", id: nil, sense_function: "", output_vector_length: 0, outputs: []

  def start_link(cortex_pid) do
    Task.start_link(fn -> init(cortex_pid) end)
  end

  defp init(cortex_pid) do
    receive do
      {:init, sensor} -> loop(sensor, cortex_pid)
      {:terminate} -> send cortex_pid, {:ok, self}
    end
  end

  defp loop(sensor, cortex_pid) do
     receive do
      {:sync} ->
        for process <- sensor.outputs, do: send process, {:forward, self, sense_function(sensor)}
        loop(sensor, cortex_pid)
      {:terminate} -> send cortex_pid, {:ok, self}
    end
  end

  defp sense_function(sensor),
    do: apply(__MODULE__, String.to_atom(sensor.sense_function), [sensor.output_vector_length])

  def all_ones(output_vector_length) do
    for _ <- 1..output_vector_length, do: 1
  end

end