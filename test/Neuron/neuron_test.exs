defmodule Cerebrum.Neuron.NeuronTest do
  use ExUnit.Case, async: true
  import Cerebrum.Neuron
  doctest Cerebrum.Neuron

   test "Creates neurons determined by the number of neurons required" do
    bias_function = fn _ -> 0.5 end
    activation_function = "sigmoid"
    number_of_neurons = 3

    expected =
    [
        %Cerebrum.Neuron{name: "neuron0", activation_function: "sigmoid", bias: 0.5 },
        %Cerebrum.Neuron{name: "neuron1", activation_function: "sigmoid", bias: 0.5 },
        %Cerebrum.Neuron{name: "neuron2", activation_function: "sigmoid", bias: 0.5 }
    ]

    assert expected == create(number_of_neurons, bias_function, activation_function)

  end

  test "Creates buckets of neurons partitioned by bucket densities" do
    bias_function = fn _ -> 0.5 end
    activation_function = "sigmoid"
    bucket_densities = [1, 2, 3]

    expected =
    [
      [
        %Cerebrum.Neuron{name: "neuron0", activation_function: "sigmoid", bias: 0.5 }
      ],
      [
        %Cerebrum.Neuron{name: "neuron1", activation_function: "sigmoid", bias: 0.5 },
        %Cerebrum.Neuron{name: "neuron2", activation_function: "sigmoid", bias: 0.5 }
      ],
      [
        %Cerebrum.Neuron{name: "neuron3", activation_function: "sigmoid", bias: 0.5 },
        %Cerebrum.Neuron{name: "neuron4", activation_function: "sigmoid", bias: 0.5 },
        %Cerebrum.Neuron{name: "neuron5", activation_function: "sigmoid", bias: 0.5 }
      ]
    ]

    assert expected == buckets(bucket_densities, bias_function, activation_function)

  end

end