defmodule Cerebrum.GenotypeCypherTest do
  use ExUnit.Case, async: true
  import Cerebrum.GenotypeCypher
  alias Cerebrum.Neuron
  alias Cerebrum.Actuator
  alias Cerebrum.Sensor
  doctest Cerebrum.GenotypeCypher

  @graph_name "cerebrum"

  test "Returns a cypher to create a neuron" do
    neuron = %Neuron{name: "neuron_id", activation_function: "sigmoid", bias: 0.1}

    assert create_neuron_cypher(neuron, @graph_name) ==
    "CREATE (neuron_id:Neuron {activation_function:'sigmoid', bias: 0.1, cerebrum: true})"
  end

  test "Returns a cypher to connect a network pair with weights [0.1]" do
    first_component_name = "first_component_name"
    second_component_name = "second_component_name"
    weights = [0.1]

    assert connect_node(first_component_name, second_component_name, weights) ==
    "CREATE (first_component_name)-[:OUTPUT{weights: [0.1]}]->(second_component_name)"
  end

  test "Returns a cypher to create a sensor" do
    sensor = %Sensor{name: "sensor_name", function_name: "sigmoid", output_vector_length: 3}

    assert create_sensor_cypher(sensor, @graph_name) ==
    "CREATE (sensor_name:Sensor {function_name: 'sigmoid', output_vector_length: 3, cerebrum: true})"
  end

  test "Returns cypher to create a simple actuator" do
    actuator = %Actuator{name: "actuator_name", function_name: "sigmoid", output_vector_length: 2}

    assert create_actuator_cypher(actuator, @graph_name) ==
    "CREATE (actuator_name:Actuator {function_name: 'sigmoid', output_vector_length: 2, cerebrum: true})"
  end

  test "Returns a cypher that associates a sensor to collection of neurons" do
    sensor = %Sensor{name: "sensor", function_name: "sigmoid", output_vector_length: 3}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}, %Neuron{name: "neuron3"}]
    weight_function = fn _ -> 0.5 end

    expected =
      [ "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron1)",
        "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron2)",
        "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron3)"]
    assert expected == create_connect_sensor_to_neurons_cypher(sensor, neurons, weight_function)
  end

  test "Returns a cypher that associates an actuator to a collection of neurons" do
    actuator = %Sensor{name: "actuator", function_name: "sigmoid", output_vector_length: 3}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}]
    weight_function = fn _ -> 0.5 end

    expected =
    ["CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(actuator)",
     "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(actuator)"]
    assert expected == create_connect_actuator_to_neurons_cypher(actuator, neurons, weight_function)
  end

  test "Returns a cypher that associates a neuron to a collection of neurons" do
    neuron = %Neuron{name: "neuron"}
    neurons = [%Neuron{name: "neuron1"}, %Neuron{name: "neuron2"}]
    weight_function = fn _ -> 0.5 end

    expected =
    ["CREATE (neuron)-[:OUTPUT{weights: [0.5]}]->(neuron1)",
     "CREATE (neuron)-[:OUTPUT{weights: [0.5]}]->(neuron2)"]
    assert expected == create_connect_neuron_to_neurons_cypher(neuron, neurons, weight_function)
  end

  test "Returns a cypher to create a neural network with one sensor, one actuator and neruons defined by hidden layer densities" do
    sensor = %Sensor{name: "sensor", function_name: "sigmoid", output_vector_length: 3}
    actuator = %Actuator{name: "actuator", function_name: "sigmoid", output_vector_length: 2}

    hidden_layer_densities = [1, 2]
    bias_function = fn _ -> 0.5 end
    activation_function = 'sigmoid'
    weight_function = fn _ -> 0.5 end

    expected =
    ["CREATE (sensor:Sensor {function_name: 'sigmoid', output_vector_length: 3, cerebrum: true})",
    "CREATE (actuator:Actuator {function_name: 'sigmoid', output_vector_length: 2, cerebrum: true})",
    "CREATE (neuron1:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (neuron2:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (neuron3:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (neuron4:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (neuron5:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron1)",
    "CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(neuron2)",
    "CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(neuron3)",
    "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(neuron4)",
    "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(neuron5)",
    "CREATE (neuron3)-[:OUTPUT{weights: [0.5]}]->(neuron4)",
    "CREATE (neuron3)-[:OUTPUT{weights: [0.5]}]->(neuron5)",
    "CREATE (neuron4)-[:OUTPUT{weights: [0.5]}]->(actuator)",
    "CREATE (neuron5)-[:OUTPUT{weights: [0.5]}]->(actuator)"]

     assert expected == create_neural_network_cypher(sensor, actuator, hidden_layer_densities, bias_function, activation_function, weight_function, @graph_name)

  end

  test "Saves a neural network with one sensor, one actuator and [1, 2] hidden layers to neo4j db" do

    cypher_list = ["CREATE (sensor:Sensor {function_name: 'sigmoid', output_vector_length: 3, cerebrum: true})",
    "CREATE (actuator:Actuator {function_name: 'sigmoid', output_vector_length: 2, cerebrum: true})",
    "CREATE (neuron1:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (neuron2:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (neuron3:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (neuron4:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (neuron5:Neuron {activation_function:'sigmoid', bias: 0.5, cerebrum: true})",
    "CREATE (sensor)-[:OUTPUT{weights: [0.5, 0.5, 0.5]}]->(neuron1)",
    "CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(neuron2)",
    "CREATE (neuron1)-[:OUTPUT{weights: [0.5]}]->(neuron3)",
    "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(neuron4)",
    "CREATE (neuron2)-[:OUTPUT{weights: [0.5]}]->(neuron5)",
    "CREATE (neuron3)-[:OUTPUT{weights: [0.5]}]->(neuron4)",
    "CREATE (neuron3)-[:OUTPUT{weights: [0.5]}]->(neuron5)",
    "CREATE (neuron4)-[:OUTPUT{weights: [0.5]}]->(actuator)",
    "CREATE (neuron5)-[:OUTPUT{weights: [0.5]}]->(actuator)"]

    assert {:ok, _message} = save(cypher_list)

  end

end