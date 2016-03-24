defmodule Cerebrum.Genotype.CypherTest do
  use ExUnit.Case, async: true
  import Cerebrum.Genotype.Cypher
  alias Cerebrum.Neuron
  alias Cerebrum.Actuator
  alias Cerebrum.Sensor
  doctest Cerebrum.Genotype.Cypher

  @graph_name "cerebrum"

  test "Returns a cypher to create a neuron" do
    neuron = %Neuron{name: "neuron_id", activation_function: "sigmoid", bias: 0.1}

    assert create_node(neuron, @graph_name) ==
    "CREATE (neuron_id:Neuron {activation_function:'sigmoid', bias: 0.1, cerebrum: true})"
  end

  test "Returns a cypher to connect a network pair with weights [0.1, 0.4, 0.5]" do
    first_node = "first_node"
    second_node = "second_node"
    weights = [0.1, 0.4, 0.5]

    assert create_relationship(first_node, second_node, weights) ==
    "CREATE (first_node)-[:OUTPUT{weights: [0.1, 0.4, 0.5]}]->(second_node)"
  end

  test "Returns a cypher to create a sensor" do
    sensor = %Sensor{name: "sensor_name", sense_function: "sigmoid", output_vector_length: 3}

    assert create_node(sensor, @graph_name) ==
    "CREATE (sensor_name:Sensor {sense_function: 'sigmoid', output_vector_length: 3, cerebrum: true})"
  end

  test "Returns cypher to create a simple actuator" do
    actuator = %Actuator{name: "actuator_name", accumulator_function: "sigmoid", accumulated_actuation_vector_length: 2}

    assert create_node(actuator, @graph_name) ==
    "CREATE (actuator_name:Actuator {accumulator_function: 'sigmoid', accumulated_actuation_vector_length: 2, cerebrum: true})"
  end

  test "Returns a cypher that connects a sensor to collection of neurons" do
    sensor = %Sensor{name: "sensor", output_vector_length: 3}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}, %Neuron{name: "neuron3"}]
    weight_function = fn _ -> 0.5 end

    expected =
      [ "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron1)",
        "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron2)",
        "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron3)"]
    assert expected == relate_sensor_to_neurons(sensor, neurons, weight_function)
  end

  test "Returns a cypher that connects an actuator to a collection of neurons" do
    actuator = %Actuator{name: "actuator", accumulator_function: "sigmoid", accumulated_actuation_vector_length: 3}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}]
    weight_function = fn _ -> 0.5 end

    expected =
    ["CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(actuator)",
     "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(actuator)"]
    assert expected == relate_actuator_to_neurons(actuator, neurons, weight_function)
  end

  test "Returns a cypher that connects a neuron to a collection of neurons" do
    neuron = %Neuron{name: "neuron"}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}]
    weight_function = fn _ -> 0.5 end

    expected =
    ["CREATE (neuron)-[:OUTPUT{weights: [0.5]}]->(neuron1)",
     "CREATE (neuron)-[:OUTPUT{weights: [0.5]}]->(neuron2)"]
    assert expected == relate_neuron_to_neurons(neuron, neurons, weight_function)
  end

  test "Returns a cypher that connects a collection of neurons to a collection of neurons" do
    neurons_left = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}]
    neurons_right = [%Neuron{name: "neuron3"}, %Neuron{name: "neuron4"}]
    weight_function = fn _ -> 0.5 end

    expected =
    ["CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(neuron3)",
     "CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(neuron4)",
     "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(neuron3)",
     "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(neuron4)"]
    assert expected == relate_neurons_to_neurons(neurons_left, neurons_right, weight_function)
  end

  test "Returns a cypher to create a neural network with one sensor, one actuator and neruons defined by hidden layer densities" do
    sensor = %Sensor{name: "sensor", sense_function: "sigmoid", output_vector_length: 3}
    actuator = %Actuator{name: "actuator", accumulator_function: "sigmoid", accumulated_actuation_vector_length: 2}

    hidden_layer_densities = [1, 2]
    bias_function = fn _ -> 0.5 end
    activation_function = 'sigmoid'
    weight_function = fn _ -> 0.5 end

    expected =
    [
      "CREATE (sensor:Sensor {sense_function: 'sigmoid', output_vector_length: 3, cerebrum: true})",
      "CREATE (actuator:Actuator {accumulator_function: 'sigmoid', accumulated_actuation_vector_length: 2, cerebrum: true})",
      "CREATE (neuron0:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
      "CREATE (neuron1:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
      "CREATE (neuron2:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
      "CREATE (neuron3:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
      "CREATE (neuron4:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
      "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron0)",
      "CREATE (neuron0)-[:OUTPUT{weights: [0.5]}]->(neuron1)",
      "CREATE (neuron0)-[:OUTPUT{weights: [0.5]}]->(neuron2)",
      "CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(neuron3)",
      "CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(neuron4)",
      "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(neuron3)",
      "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(neuron4)",
      "CREATE (neuron3)-[:OUTPUT{weights: [0.5]}]->(actuator)",
      "CREATE (neuron4)-[:OUTPUT{weights: [0.5]}]->(actuator)"
    ]
     assert expected == create_neural_network(sensor, actuator, hidden_layer_densities, bias_function, activation_function, weight_function, @graph_name)

  end

end