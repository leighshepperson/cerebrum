defmodule Cerebrum.Neuron do
  alias Cerebrum.Neuron.NeuronAgent
  defstruct name: "", activation_function: "", bias: 0

  def buckets(bucket_densities, bias_function, activation_function) do
    {_, neuron_agent} = NeuronAgent.start_link()
    bucket_densities |> Enum.map(&do_create(neuron_agent, &1, bias_function, activation_function))
  end

  def create(number_of_neurons,  bias_function, activation_function) do
    {_, neuron_agent} = NeuronAgent.start_link()
    do_create(neuron_agent, number_of_neurons, bias_function, activation_function)
  end

  defp do_create(neuron_agent, number_of_neurons, bias_function, activation_function) do
    for _ <- 1..number_of_neurons, do: NeuronAgent.create_neuron(neuron_agent, bias_function, activation_function)
  end

end