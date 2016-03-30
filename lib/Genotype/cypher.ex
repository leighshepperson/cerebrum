defmodule Cerebrum.Genotype.Cypher do
  alias Cerebrum.Neuron
  alias Cerebrum.Sensor
  alias Cerebrum.Actuator

  def create_node(%Neuron{name: name, activation_function: activation_function, bias: bias}, id_function, graph_name) do
    "CREATE (#{name}:Neuron {type: 'neuron', id: #{id_function.()}, activation_function: '#{activation_function}', bias: #{bias}, #{graph_name}: true})"
  end

  def create_node(%Sensor{name: name, sense_function: sense_function, output_vector_length: output_vector_length}, id_function, graph_name) do
    "CREATE (#{name}:Sensor {type: 'sensor', id: #{id_function.()}, sense_function: '#{sense_function}', output_vector_length: #{output_vector_length}, #{graph_name}: true})"
  end

  def create_node(%Actuator{name: name, accumulator_function: accumulator_function, accumulated_actuation_vector_length: accumulated_actuation_vector_length}, id_function, graph_name) do
    "CREATE (#{name}:Actuator {type: 'actuator', id: #{id_function.()}, accumulator_function: '#{accumulator_function}', accumulated_actuation_vector_length: #{accumulated_actuation_vector_length}, #{graph_name}: true})"
  end

  def create_relationship(first_node, second_node, weights)  do
    "CREATE (#{first_node})-[:OUTPUT{weights: [#{Enum.join(weights, ", ")}]}]->(#{second_node})"
  end

  def relate_sensor_to_neurons(sensor, neurons, weight_function) do
    weights = 1..sensor.output_vector_length |> Enum.map(&weight_function.(&1))
    neurons |> Enum.map(&create_relationship(sensor.name, &1.name, weights))
  end

  def relate_actuator_to_neurons(actuator, neurons, weight_function) do
    weights = [weight_function.(1)]
    neurons |> Enum.map(&create_relationship(&1.name, actuator.name, weights))
  end

  def relate_neuron_to_neurons(neuron, neurons, weight_function) do
    weights = [weight_function.(1)]
    neurons |> Enum.map(&create_relationship(neuron.name, &1.name, weights))
  end

  def relate_neurons_to_neurons(neurons_left, neurons_right, weight_function) do
    neurons_left
    |> Enum.map(&relate_neuron_to_neurons(&1, neurons_right, weight_function))
    |> List.flatten
  end

  def create_neural_network(sensor, actuator, hidden_layer_densities, bias_function, neuron_activation_function, weight_function, id_function, graph_name) do
    neuron_layers = actuator
      |> layer_densities(hidden_layer_densities)
      |> Neuron.create_layers(bias_function, neuron_activation_function)

    nodes = [sensor, actuator, neuron_layers] |> List.flatten |> Enum.map(&create_node(&1, id_function, graph_name))

    relations = relate_network(sensor, neuron_layers, actuator, weight_function)

    [nodes | relations] |> List.flatten
  end

  defp layer_densities(actuator, hidden_layer_densities) do
    [actuator.accumulated_actuation_vector_length | hidden_layer_densities |> Enum.reverse] |> Enum.reverse
  end

  defp relate_network(nil, [last_neuron_layer | []], actuator, weight_function) do
    [relate_actuator_to_neurons(actuator, last_neuron_layer, weight_function)]
  end

  defp relate_network(nil, [neuron_layer | [next_neuron_layer | _] = remaining_neuron_layers], actuator, weight_function) do
    [
      relate_neurons_to_neurons(neuron_layer, next_neuron_layer, weight_function)
      | relate_network(nil, remaining_neuron_layers, actuator, weight_function)
    ]
  end

  defp relate_network(sensor, [first_neuron_layer | _] = neurons_by_layers, actuator, weight_function) do
    [
      relate_sensor_to_neurons(sensor, first_neuron_layer, weight_function)
      | relate_network(nil, neurons_by_layers, actuator, weight_function)
    ]
  end

end