defmodule Cerebrum.Neuron do
  defstruct name: "", activation_function: "", bias: 0

  def create_neurons_by_layers(layer_densities, bias_function, neuron_activation_function) do
    {_, count_pid} = Agent.start_link(fn -> 0 end)
    neurons_by_layers = layer_densities |> Enum.map(&create_neurons(&1, count_pid, bias_function, neuron_activation_function))
    Agent.stop(count_pid)

    neurons_by_layers
  end

  def create_neurons(number_of_neurons, count_pid, bias_function, activation_function) do
    for _ <- 1..number_of_neurons, do: create_neuron(count_pid, bias_function, activation_function)
  end

  def create_neuron(count_pid, bias_function, activation_function) do
    index = Agent.get_and_update(count_pid, &{&1 + 1, &1 + 1})
    %Cerebrum.Neuron{name: "neuron#{index}", bias: bias_function.(index), activation_function: activation_function}
  end

end