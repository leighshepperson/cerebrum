defmodule Cerebrum.ExoselfTest do
  use ExUnit.Case, async: true
  import Cerebrum.Exoself
  doctest Cerebrum.Exoself


  test "g" do
    IO.inspect(get("cerebrum1"))


  end

end