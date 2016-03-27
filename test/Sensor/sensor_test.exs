defmodule Cerebrum.SensorTest do
  use ExUnit.Case, async: true
  import Cerebrum.Sensor
  doctest Cerebrum.Sensor

  test "The function 'all_ones' returns a list of n-many 1's" do
    assert all_ones(4) == [1, 1, 1, 1]
    assert all_ones(7) == [1, 1, 1, 1, 1, 1, 1]
  end

  test "When I recieve a sync message, then I send my output to all of my outputs" do
    {_, pid0} = Task.start_link(fn -> test_loop end)
    {_, pid1} = Task.start_link(fn -> test_loop end)

    sensor = %{
      sense_function: "all_ones",
      output_vector_length: 2,
      name: "new",
      outputs: [self(), pid0, pid1]
    }

    cortex = self()
    {_, sensor_pid} = start_link(cortex)
    send sensor_pid, {:init, sensor}

    send sensor_pid, {:sync}

    assert_receive {:forward, sensor_pid, [1, 1]}
    assert :erlang.process_info(pid0, :messages) == {:messages, [{:forward, sensor_pid, [1, 1]}]}
    assert :erlang.process_info(pid1, :messages) == {:messages, [{:forward, sensor_pid, [1, 1]}]}
  end

  test "When I recieve a terminate message, then I send :ok to the caller" do
    sensor = %{sense_function: "all_ones", output_vector_length: 2, name: "new", outputs: [self()]}

    cortex = self()
    {_, sensor_pid} = start_link(cortex)
    send sensor_pid, {:init, sensor}

    send sensor_pid, {:terminate}

    assert_receive {:ok, sensor_pid}
  end

  defp test_loop do
    test_loop
  end

end