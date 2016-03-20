defmodule Cerebrum.GenotypeCypher do
alias Cerebrum.Neuron
alias Cerebrum.Sensor
alias Cerebrum.Actuator
alias Cerebrum.CounterAgent
alias UUID

def create_neuron_cypher(%Neuron{name: name, activation_function: activation_function, bias: bias}) do
  "CREATE (#{name}:Neuron {activation_function:'#{activation_function}', bias: #{bias}})"
end

def connect_network(first_component_name, second_component_name, weights)  do
  "CREATE (#{first_component_name})-[:OUTPUT{weights: [#{Enum.join(weights, ", ")}]}]->(#{second_component_name})"
end

def create_sensor_cypher(%Sensor{name: name, function_name: function_name, output_vector_length: output_vector_length}) do
 "CREATE (#{name}:Sensor {function_name: '#{function_name}', output_vector_length: #{output_vector_length}})"
end

def create_actuator_cypher(%Actuator{name: name, function_name: function_name, output_vector_length: output_vector_length}) do
 "CREATE (#{name}:Actuator {function_name: '#{function_name}', output_vector_length: #{output_vector_length}})"
end

def create_neurons1(layer_densities, activation_function, bias) do
  total_number_of_neurons = layer_densities |> Enum.sum
  (for i <- 1..total_number_of_neurons,
    do: create_neuron_cypher(%Neuron{name: "neuron#{i}", activation_function: activation_function, bias: bias.(i)}))
  |> Enum.join(" ")
end

def create_sensor_to_neuron_cypher(sensor, neurons, weight_function) do
  weights = 1..sensor.output_vector_length |> Enum.map(&weight_function.(&1))
  neurons
  |> Enum.map(&connect_network(sensor.name, &1.name, weights))
  |> Enum.join(" ")
end

def create_neuron_to_actuator_cypher(actuator, neurons, weight_function) do
  weights = [0.5]
  neurons
  |> Enum.map(&connect_network(&1.name, actuator.name, weights))
  |> Enum.join(" ")
end

def create_neuron_to_neuron_cypher(neuron, neurons, weight_function) do
  weights = [0.5]
  neurons
  |> Enum.map(&connect_network(neuron.name, &1.name, weights))
  |> Enum.join(" ")
end

def create_neural_network_cypher(sensor, actuator, hidden_layer_densities) do
  layer_densities = [actuator.output_vector_length | hidden_layer_densities |> Enum.reverse] |> Enum.reverse
  create_neurons_by_layer(layer_densities)

end

defp create_neurons_by_layer(layer_densities) do
  count = 0
  {_, count_pid} = Agent.start_link(fn -> 0 end)
  neurons = layer_densities |> Enum.map(&(for _ <- 1..&1, do: create_neuron(0.5, "sigmoid", count_pid)))
  Agent.stop(count_pid)
  neurons
end

defp create_neuron(bias, activation_function, count_pid) do
  current_index = Agent.get_and_update(count_pid, fn i -> {i + 1, i+ 1} end)
  %Neuron{name: "neuron#{current_index}", bias: bias, activation_function: activation_function}
end

end