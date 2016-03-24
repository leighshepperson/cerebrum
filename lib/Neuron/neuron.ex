defmodule Cerebrum.Neuron do
  alias Cerebrum.Neuron.NeuronAgent
  alias ExAlgebra.Vector

  defstruct name: "", activation_function: "", bias: 0, inputs: %{}, outputs: []

  def create_layers(layer_densities, bias_function, activation_function) do
    {_, neuron_agent} = NeuronAgent.start_link()
    layer_densities |> Enum.map(&do_create(neuron_agent, &1, bias_function, activation_function))
  end

  def create(number_of_neurons,  bias_function, activation_function) do
    {_, neuron_agent} = NeuronAgent.start_link()
    do_create(neuron_agent, number_of_neurons, bias_function, activation_function)
  end

  defp do_create(neuron_agent, number_of_neurons, bias_function, activation_function) do
    for _ <- 1..number_of_neurons, do: NeuronAgent.create_neuron(neuron_agent, bias_function, activation_function)
  end

  def start_link(neuron, cortex) do
    Task.start_link(fn -> loop(neuron, cortex, neuron.inputs, 0) end)
  end

  defp loop(neuron, cortex, inputs, acc) when inputs == %{} do
    output = apply_activation_function(neuron, acc + neuron.bias)
    for pid <- neuron.outputs, do: send pid, {:forward, self(), [output]}
    loop(neuron, cortex, neuron.inputs, 0)
  end

  defp loop(neuron, cortex, inputs, acc) do
    receive do
      {:forward, input, output} ->
        {weights, reduced_inputs} = Map.pop(inputs, input)
        acc = acc + Vector.dot(output, weights)
        loop(neuron, cortex, reduced_inputs, acc)
      {:backup} -> send cortex, {:backup, self(), neuron}
      {:terminate} -> send cortex, :ok
    end
  end

  defp apply_activation_function(neuron, input),
    do: apply(__MODULE__, String.to_atom(neuron.activation_function), [input])

  def sigmoid(input) do
    1 / (1 + :math.exp(-input))
  end

end