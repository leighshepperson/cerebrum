defmodule Cerebrum.Neuron.NeuronAgentTest do
  use ExUnit.Case, async: true
  import Cerebrum.Neuron.NeuronAgent
  doctest Cerebrum.Neuron.NeuronAgent

  test "Creates neurons with incrementing indexed names" do
    {:ok, neuron_agent} = start_link()
    bias = fn _ -> 0.1 end
    activation_function = "sigmoid"
    assert create_neuron(neuron_agent, bias, activation_function).name == "neuron0"
    assert create_neuron(neuron_agent, bias, activation_function).name == "neuron1"
    assert create_neuron(neuron_agent, bias, activation_function).name == "neuron2"
  end

end