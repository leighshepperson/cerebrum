defmodule Cerebrum.GenotypeCypher do
alias Cerebrum.Neuron
alias Cerebrum.Sensor
alias Cerebrum.Actuator
alias Neo4j.Sips, as: Neo4j

def create_neuron_cypher(%Neuron{name: name, activation_function: activation_function, bias: bias}, graph_name) do
  "CREATE (#{name}:Neuron {activation_function:'#{activation_function}', bias: #{bias}, #{graph_name}: true})"
end

def create_sensor_cypher(%Sensor{name: name, function_name: function_name, output_vector_length: output_vector_length}, graph_name) do
  "CREATE (#{name}:Sensor {function_name: '#{function_name}', output_vector_length: #{output_vector_length}, #{graph_name}: true})"
end

def create_actuator_cypher(%Actuator{name: name, function_name: function_name, output_vector_length: output_vector_length}, graph_name) do
  "CREATE (#{name}:Actuator {function_name: '#{function_name}', output_vector_length: #{output_vector_length}, #{graph_name}: true})"
end

def connect_node(first_component_name, second_component_name, weights)  do
  "CREATE (#{first_component_name})-[:OUTPUT{weights: [#{Enum.join(weights, ", ")}]}]->(#{second_component_name})"
end

def create_connect_sensor_to_neurons_cypher(sensor, neurons, weight_function) do
  weights = 1..sensor.output_vector_length |> Enum.map(&weight_function.(&1))
  neurons |> Enum.map(&connect_node(sensor.name, &1.name, weights))
end

def create_connect_actuator_to_neurons_cypher(actuator, neurons, weight_function) do
  weights = [weight_function.(1)]
  neurons |> Enum.map(&connect_node(&1.name, actuator.name, weights))
end

def create_connect_neuron_to_neurons_cypher(neuron, neurons, weight_function) do
  weights = [weight_function.(1)]
  neurons |> Enum.map(&connect_node(neuron.name, &1.name, weights))
end

def create_neural_network_cypher(sensor, actuator, hidden_layer_densities, bias_function, neuron_activation_function, weight_function, graph_name) do
  layer_densities = [actuator.output_vector_length | hidden_layer_densities |> Enum.reverse] |> Enum.reverse
  neurons_by_layers = Neuron.create_neurons_by_layers(layer_densities, bias_function, neuron_activation_function)

  sensor_cypher = create_sensor_cypher(sensor, graph_name)
  actuator_cypher = create_actuator_cypher(actuator, graph_name)
  neuron_cyphers = neurons_by_layers |> List.flatten |> Enum.map(&create_neuron_cypher(&1, graph_name))

  connection_cyphers = create_connections(sensor, neurons_by_layers, actuator, weight_function)

  [[sensor_cypher, actuator_cypher | neuron_cyphers] | connection_cyphers] |> List.flatten
end

def save(cypher_list) do
  cypher = cypher_list |> Enum.join(" ")

  case Neo4j.query(Neo4j.conn(), cypher) do
    {:ok, body}      -> {:ok, body}
    {:error, reason} -> {:error, reason}
  end

end

defp create_connections(nil, [first_neuron_layer | []], actuator, weight_function) do
  [create_connect_actuator_to_neurons_cypher(actuator, first_neuron_layer, weight_function)]
end

defp create_connections(nil, [first_neuron_layer | [second_neuron_layer | _] = remaining_neuron_layers] = neurons_by_layers, actuator, weight_function) do
  connect_neurons_to_neurons_cypher = first_neuron_layer
  |> Enum.map(&create_connect_neuron_to_neurons_cypher(&1, second_neuron_layer, weight_function))

  [connect_neurons_to_neurons_cypher | create_connections(nil, remaining_neuron_layers, actuator, weight_function)]
end

defp create_connections(sensor, [first_neuron_layer | _] = neurons_by_layers, actuator, weight_function) do
  connect_sensor_to_neurons_cypher = create_connect_sensor_to_neurons_cypher(sensor, first_neuron_layer, weight_function)

  [connect_sensor_to_neurons_cypher | create_connections(nil, neurons_by_layers, actuator, weight_function)]
end

end