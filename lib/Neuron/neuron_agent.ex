defmodule Cerebrum.Neuron.NeuronAgent do
alias Cerebrum.Neuron

def start_link() do
  Agent.start_link(fn -> 0 end)
end

def create_neuron(neuron_agent, bias_function, activation_function) do
  index = Agent.get_and_update(neuron_agent, &{&1, &1 + 1})
  %Neuron{name: "neuron#{index}", bias: bias_function.(index), activation_function: activation_function}
end

end