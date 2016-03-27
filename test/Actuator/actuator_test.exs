defmodule Cerebrum.ActuatorTest do
  use ExUnit.Case, async: true
  import Cerebrum.Actuator
  import Mock
  doctest Cerebrum.Actuator

  test "When I recieve I recieve the :terminate message, then I send {:ok, self}" do
    {_, pid0} = Task.start_link(fn -> test_loop end)

    actuator = %Cerebrum.Actuator{accumulator_function: "return", inputs: [pid0]}

    cortex = self
    {_, pid} = start_link(cortex)
    send pid, {:init, actuator}

    send pid, {:terminate}

    assert_receive {:ok, ^pid}

  end

  test "When I recieve all my inputs, then I send the :sync message" do
    {_, pid0} = Task.start_link(fn -> test_loop end)
    {_, pid1} = Task.start_link(fn -> test_loop end)
    {_, pid2} = Task.start_link(fn -> test_loop end)

    actuator = %Cerebrum.Actuator{accumulator_function: "return", inputs: [pid0, pid1, pid2]}

    cortex = self
    {_, pid} = start_link(cortex)
    send pid, {:init, actuator}

    send pid, {:forward, pid0, 0}
    refute_receive {:sync, ^pid}

    send pid, {:forward, pid1, 1}
    refute_receive {:sync, ^pid}

    send pid, {:forward, pid2, 2}
    assert_receive {:sync, ^pid}, 500

  end

  test_with_mock "When I recieve all my inputs, then I execute my accumulator_function with accumulated output list ordered by pre-defined input list", Cerebrum.Actuator, [:passthrough], [] do
    {_, pid0} = Task.start_link(fn -> test_loop end)
    {_, pid1} = Task.start_link(fn -> test_loop end)
    {_, pid2} = Task.start_link(fn -> test_loop end)

    actuator = %Cerebrum.Actuator{accumulator_function: "return", inputs: [pid0, pid1, pid2]}

    cortex = self
    {_, pid} = start_link(cortex)
    send pid, {:init, actuator}

    send pid, {:forward, pid0, 0}
    send pid, {:forward, pid1, 1}
    send pid, {:forward, pid2, 2}

    assert called Cerebrum.Actuator.return([0, 1, 2])

    send pid, {:forward, pid0, 0}
    send pid, {:forward, pid2, 2}
    send pid, {:forward, pid1, 1}

    assert called Cerebrum.Actuator.return([0, 1, 2])

    send pid, {:forward, pid1, 1}
    send pid, {:forward, pid0, 0}
    send pid, {:forward, pid2, 2}

    assert called Cerebrum.Actuator.return([0, 1, 2])

    send pid, {:forward, pid1, 1}
    send pid, {:forward, pid2, 2}
    send pid, {:forward, pid0, 0}

    assert called Cerebrum.Actuator.return([0, 1, 2])

    send pid, {:forward, pid2, 2}
    send pid, {:forward, pid1, 1}
    send pid, {:forward, pid0, 0}

    assert called Cerebrum.Actuator.return([0, 1, 2])

    send pid, {:forward, pid2, 2}
    send pid, {:forward, pid0, 0}
    send pid, {:forward, pid1, 1}

    assert called Cerebrum.Actuator.return([0, 1, 2])

  end

  defp test_loop do
    test_loop
  end

end