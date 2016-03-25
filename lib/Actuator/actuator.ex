defmodule Cerebrum.Actuator do
  defstruct name: "", accumulator_function: "", accumulated_actuation_vector_length: 0, inputs: []

  def start_link(actuator, cortex) do
    Task.start_link(fn -> loop(actuator, actuator.inputs, [], cortex) end)
  end

  defp loop(actuator, [], acc, cortex) do
    result = acc |> Enum.reverse
    apply_accumulator_function(actuator, result)
    send cortex, {:sync, self}
    loop(actuator, actuator.inputs, [], cortex)
  end

  defp loop(actuator, [input | remaining_inputs], acc, cortex) do
    receive do
      {:forward, ^input, output} ->
        loop(actuator, remaining_inputs, [output | acc], cortex)
      {:terminate} -> send cortex, {:ok, self}
    end
  end

  defp apply_accumulator_function(actuator, input),
    do: apply(__MODULE__, String.to_atom(actuator.accumulator_function), [input])

  def return(input) do
    input
  end

end