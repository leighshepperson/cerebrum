defmodule Cerebrum.CortexTest do
  use ExUnit.Case, async: true
  import Cerebrum.Cortex
  doctest Cerebrum.Cortex

  setup context do
    exo_self = self

    {_, cortex_pid} = Cerebrum.Cortex.start_link(exo_self)
    {_, sensor0_pid} = Cerebrum.Sensor.start_link(cortex_pid)
    {_, sensor1_pid} = Cerebrum.Sensor.start_link(cortex_pid)
    {_, neuron0_pid} = Cerebrum.Neuron.start_link(cortex_pid)
    {_, neuron1_pid} = Cerebrum.Neuron.start_link(cortex_pid)
    {_, actuator0_pid} = Cerebrum.Actuator.start_link(cortex_pid)

    sensor0 = %Cerebrum.Sensor{
      name: "sensor0",
      sense_function: "all_ones",
      outputs: [neuron0_pid],
      output_vector_length: 2
    }

    sensor1 = %Cerebrum.Sensor{
      name: "sensor1",
      sense_function: "all_ones",
      outputs: [neuron1_pid],
      output_vector_length: 1
    }

    neuron0 = %Cerebrum.Neuron{
      name: "neuron0",
      activation_function: "sigmoid",
      bias: 0.1,
      inputs: %{sensor0_pid => [0.3, 0.5]},
      outputs: [neuron1_pid]
    }

    neuron1 = %Cerebrum.Neuron{
      name: "neuron1",
      activation_function: "sigmoid",
      bias: 0.4,
      inputs: %{neuron0_pid => [0.2], sensor1_pid => [0.9]},
      outputs: [actuator0_pid]
    }

    actuator0 = %Cerebrum.Actuator{
      name: "actuator0",
      accumulator_function: "return",
      accumulated_actuation_vector_length: 1,
      inputs: [neuron1_pid]
    }

    cortex = %Cerebrum.Cortex{
      sensor_pids: [sensor0_pid, sensor1_pid],
      neuron_pids: [neuron0_pid, neuron1_pid],
      actuator_pids: [actuator0_pid]
    }

    send sensor0_pid, {:init, sensor0}
    send sensor1_pid, {:init, sensor1}
    send actuator0_pid, {:init, actuator0}
    send neuron0_pid, {:init, neuron0}
    send neuron1_pid, {:init, neuron1}

    {:ok, neurons: [neuron1, neuron0], cortex_pid: cortex_pid, cortex: cortex, exo_self: exo_self}
  end

  test "When i receive a message from the exo_self, then I receive the :backup message and I terminate", context do

    cortex = context[:cortex]
    cortex_pid = context[:cortex_pid]
    exo_self = context[:exo_self]
    neurons = context[:neurons]

    send cortex_pid, {exo_self, cortex, 8}
    ref  = Process.monitor(cortex_pid)

    assert_receive {:backup, cortex_pid, ^neurons}
    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500

  end

  test "When i receive a terminate message, then I terminate", context do

    cortex = context[:cortex]
    cortex_pid = context[:cortex_pid]
    exo_self = context[:exo_self]
    neurons = context[:neurons]

    send cortex_pid, {exo_self, cortex, 80000}
    ref  = Process.monitor(cortex_pid)
    send cortex_pid, {:terminate}

    assert_receive {:DOWN, ^ref, :process, _, :normal}, 500

  end

end