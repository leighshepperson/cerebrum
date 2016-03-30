defmodule Cerebrum.Neuron.NeuronTest do
  use ExUnit.Case, async: true
  import Cerebrum.Neuron
  doctest Cerebrum.Neuron

  test "Creates n-many neurons" do
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

  test "Creates layers of neurons partitioned by layer densities" do
    bias_function = fn _ -> 0.5 end
    activation_function = "sigmoid"
    layer_densities = [1, 2, 3]

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

    assert expected == create_layers(layer_densities, bias_function, activation_function)

  end

  test "If I receive all my inputs, then I forward my output to all my outputs" do

    {_, pid0} = Task.start_link(fn -> 0 end)
    {_, pid1} = Task.start_link(fn -> 0 end)
    {_, pid2} = Task.start_link(fn -> 0 end)
    {_, pid3} = Task.start_link(fn -> 0 end)

    {_, pid4} = Task.start_link(fn -> test_loop end)
    {_, pid5} = Task.start_link(fn -> test_loop end)
    {_, pid6} = Task.start_link(fn -> test_loop end)
    {_, pid7} = Task.start_link(fn -> test_loop end)

    neuron = %Cerebrum.Neuron{name: "neuron", activation_function: "sigmoid", bias: 0.4}

    inputs = %{pid0 => [0.1], pid1 => [0.3], pid2 => [0.1, 0.3], pid3 => [0.2, 0.3, -0.4]}
    outputs = [self(), pid4, pid5, pid6, pid7]
    neuron = %{neuron | inputs: inputs, outputs: outputs}

    cortex = self()
    {_, neuron_pid} = start_link(cortex)
    send neuron_pid, {:init, neuron}

    send neuron_pid, {:forward, pid0, [0.7]}
    send neuron_pid, {:forward, pid1, [0.2]}
    send neuron_pid, {:forward, pid2, [0.1, 0.4]}
    send neuron_pid, {:forward, pid3, [0.2, 0.3, 0.1]}

    assert_receive {:forward, neuron_pid, [0.679178699175393]}
    assert :erlang.process_info(pid4, :messages) == {:messages, [{:forward, neuron_pid, [0.679178699175393]}]}
    assert :erlang.process_info(pid5, :messages) == {:messages, [{:forward, neuron_pid, [0.679178699175393]}]}
    assert :erlang.process_info(pid6, :messages) == {:messages, [{:forward, neuron_pid, [0.679178699175393]}]}
    assert :erlang.process_info(pid7, :messages) == {:messages, [{:forward, neuron_pid, [0.679178699175393]}]}
  end

  test "When I receive a terminate message, then I return :ok to the cortex" do
    {_, pid0} = Task.start_link(fn -> 0 end)

    neuron = %Cerebrum.Neuron{name: "neuron", activation_function: "sigmoid", bias: 0.4}

    inputs = %{pid0 => [0.1]}
    outputs = [self()]
    neuron = %{neuron | inputs: inputs, outputs: outputs}

    cortex = self()
    {_, neuron_pid} = start_link(cortex)
    send neuron_pid, {:init, neuron}

    send neuron_pid, {:terminate}

    assert_receive {:ok, neuron_pid}
  end

  test "When I receive a backup message, then I return the neuron to the cortex" do
    {_, pid0} = Task.start_link(fn -> 0 end)

    neuron = %Cerebrum.Neuron{name: "neuron", activation_function: "sigmoid", bias: 0.4}

    inputs = %{pid0 => [0.1]}
    outputs = [self()]
    neuron = %{neuron | inputs: inputs, outputs: outputs}

    {_, neuron_pid} = start_link(self)
    send neuron_pid, {:init, neuron}

    send neuron_pid, {:backup}

    assert_receive {:backup, neuron_pid, neuron}
  end

  defp test_loop do
   test_loop
  end

end