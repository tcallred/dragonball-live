defmodule Dragonball.PlayerTest do
  use ExUnit.Case, async: true
  alias Dragonball.Player

  test "new player has correct properties" do
    john = Player.new("John")

    assert john == %Player{
             name: "John",
             id: "",
             charges: 0,
             state: :alive
           }
  end

  test "alive or super players should be alive" do
    assert Player.is_alive?(%Player{state: :alive})
    assert Player.is_alive?(%Player{state: :super})
    assert not Player.is_alive?(%Player{state: :dead})
  end
end
