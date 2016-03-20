defmodule Cerebrum.GenotypeCypherTest do
  use ExUnit.Case, async: true
  import Cerebrum.GenotypeCypher
  alias Cerebrum.Neuron
  alias Cerebrum.Actuator
  alias Cerebrum.Sensor
  doctest Cerebrum.GenotypeCypher

  test "Returns a cypher to create a neuron" do
    neuron = %Neuron{name: "neuron_id", activation_function: "sigmoid", bias: 0.1}

    assert create_neuron_cypher(neuron) ==
    "CREATE (neuron_id:Neuron {activation_function:'sigmoid', bias: 0.1})"
  end

  test "Returns a cypher to connect a network pair with weights [0.1]" do
    first_component_name = "first_component_name"
    second_component_name = "second_component_name"
    weights = [0.1]

    assert connect_network(first_component_name, second_component_name, weights) ==
    "CREATE (first_component_name)-[:OUTPUT{weights: [0.1]}]->(second_component_name)"
  end

  test "Returns a cypher to create a sensor" do
    sensor = %Sensor{name: "sensor_name", function_name: "sigmoid", output_vector_length: 3}

    assert create_sensor_cypher(sensor) ==
    "CREATE (sensor_name:Sensor {function_name: 'sigmoid', output_vector_length: 3})"
  end

  test "Returns cypher to create a simple actuator" do
    actuator = %Actuator{name: "actuator_name", function_name: "sigmoid", output_vector_length: 2}

    assert create_actuator_cypher(actuator) ==
    "CREATE (actuator_name:Actuator {function_name: 'sigmoid', output_vector_length: 2})"
  end

  test "Returns a cypher that associates a sensor to collection of neurons" do
    sensor = %Sensor{name: "sensor", function_name: "sigmoid", output_vector_length: 3}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}, %Neuron{name: "neuron3"}]
    weight_function = fn i -> 0.5 end

    expected = "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron1) CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron2) CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron3)"
    assert expected == create_sensor_to_neuron_cypher(sensor, neurons, weight_function)
  end

  test "Returns a cypher to create neurons determined by layer density and named by neuron<i>" do
    layer_densities = [1, 2]
    bias = fn i -> 0.5 end
    activation_function = 'sigmoid'
    expected =
      """
      CREATE (neuron1:Neuron {activation_function:'sigmoid', bias: 0.5}) CREATE (neuron2:Neuron {activation_function:'sigmoid', bias: 0.5}) CREATE (neuron3:Neuron {activation_function:'sigmoid', bias: 0.5})
      """
    assert create_neurons1(layer_densities, activation_function, bias)
  end

  test "Returns a cypher that associates an actuator to a collection of neurons" do
    actuator = %Sensor{name: "actuator", function_name: "sigmoid", output_vector_length: 3}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}]
    weight_function = fn i -> 0.5 end

    expected = "CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(actuator) CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(actuator)"
    assert expected == create_neuron_to_actuator_cypher(actuator, neurons, weight_function)
  end

  test "Returns a cypher that associates a neuron to a collection of neurons" do
    neuron = %Neuron{name: "neuron"}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}]
    weight_function = fn i -> 0.5 end

    expected = "CREATE (neuron)-[:OUTPUT{weights: [0.5]}]->(neuron1) CREATE (neuron)-[:OUTPUT{weights: [0.5]}]->(neuron2)"
    assert expected == create_neuron_to_neuron_cypher(neuron, neurons, weight_function)
  end

  test "Returns a cypher to create a neural network with one sensor, one actuator and neruons defined by hidden layer densities" do
    sensor = %Sensor{name: "sensor_name", function_name: "sigmoid", output_vector_length: 3}
    actuator = %Actuator{name: "actuator_name", function_name: "sigmoid", output_vector_length: 2}
    hidden_layer_densities = [1, 2]
    #create_genotype(sensor, actuator, hidden_layer_densities)

    create_neural_network_cypher(sensor, actuator, hidden_layer_densities)
  end

end