defmodule Cerebrum.Sensor do
  defstruct name: "", sense_function: "", output_vector_length: 0

  def start_link(sensor, cortex) do
    Task.start_link(fn -> loop(sensor, cortex) end)
  end

  defp loop(sensor, cortex) do
     receive do
      {:sync} ->
        for process <- sensor.outputs, do: send process, {:forward, self(), sense_function(sensor)}
        loop(sensor, cortex)
      {:terminate} -> send cortex, {self(), :ok}
    end
  end

  defp sense_function(sensor),
    do: apply(__MODULE__, String.to_atom(sensor.sense_function), [sensor.output_vector_length])

  def all_ones(output_vector_length) do
    for _ <- 1..output_vector_length, do: 1
  end

end