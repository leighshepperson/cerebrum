defmodule Cerebrum.Actuator do
  defstruct name: "", accumulator_function: "", accumulated_actuation_vector_length: 0, inputs: []

  def start_link(cortex_pid) do
    Task.start_link(fn -> init(cortex_pid) end)
  end

  defp init(cortex_pid) do
    receive do
      {:init, actuator} -> loop(actuator, actuator.inputs, [], cortex_pid)
      {:terminate} -> send cortex_pid, {:ok, self}
    end
  end

  defp loop(actuator, [], acc, cortex_pid) do
    result = acc |> Enum.reverse
    apply_accumulator_function(actuator, result)
    send cortex_pid, {:sync, self}
    loop(actuator, actuator.inputs, [], cortex_pid)
  end

  defp loop(actuator, [input | remaining_inputs], acc, cortex_pid) do
    receive do
      {:forward, ^input, output} ->
        loop(actuator, remaining_inputs, [output | acc], cortex_pid)
      {:terminate} -> send cortex_pid, {:ok, self}
    end
  end

  defp apply_accumulator_function(actuator, input),
    do: apply(__MODULE__, String.to_atom(actuator.accumulator_function), [input])

  def return(input) do
    input
  end

end