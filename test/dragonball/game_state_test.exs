defmodule Dragonball.GameStateTest do
  use ExUnit.Case, async: true
  alias Dragonball.GameState
  alias Dragonball.Player
  alias Dragonball.Move

  test "two players, one killed by kamehameha" do
    john = %Player{
      name: "John",
      id: "1",
      charges: 1,
      state: :alive
    }
    mark = %Player{
      name: "Mark",
      id: "2",
      charges: 1,
      state: :alive
    }

    game = %GameState{
      status: :playing,
      players: [john, mark],
      moves_played: [],
    }

    turn_moves = %{
      john.id => Move.new(:kamehameha, mark.id),
      mark.id => Move.new(:charge)
    }

    game_after_process = %GameState{
      status: :done,
      players: [
        %Player{john | charges: 0},
        %Player{mark | charges: 0, state: :dead},
      ],
      moves_played: [turn_moves],
      winner: john.id
    }

    assert GameState.process_turn(game, turn_moves) == game_after_process
  end

  test "two players, one blocks kamehameha" do
    john = %Player{
      name: "John",
      id: "1",
      charges: 1,
      state: :alive
    }
    mark = %Player{
      name: "Mark",
      id: "2",
      charges: 1,
      state: :alive
    }

    game = %GameState{
      status: :playing,
      players: [john, mark],
      moves_played: [],
    }

    turn_moves = %{
      john.id => Move.new(:kamehameha, mark.id),
      mark.id => Move.new(:block)
    }

    game_after_process = %GameState{
      status: :playing,
      players: [
        %Player{john | charges: 0},
        mark,
      ],
      moves_played: [turn_moves],
    }

    assert GameState.process_turn(game, turn_moves) == game_after_process
  end

  test "two players, disk beats kamehameha" do
    john = %Player{
      name: "John",
      id: "1",
      charges: 1,
      state: :alive
    }
    mark = %Player{
      name: "Mark",
      id: "2",
      charges: 2,
      state: :alive
    }

    game = %GameState{
      status: :playing,
      players: [john, mark],
      moves_played: [],
    }

    turn_moves = %{
      john.id => Move.new(:kamehameha, mark.id),
      mark.id => Move.new(:disk, john.id)
    }

    game_after_process = %GameState{
      status: :done,
      players: [
        %Player{john | charges: 0, state: :dead},
        %Player{mark | charges: 0},
      ],
      moves_played: [turn_moves],
      winner: mark.id
    }

    assert GameState.process_turn(game, turn_moves) == game_after_process
  end


  test "two players, special beam beats disk" do
    john = %Player{
      name: "John",
      id: "1",
      charges: 5,
      state: :alive
    }
    mark = %Player{
      name: "Mark",
      id: "2",
      charges: 2,
      state: :alive
    }

    game = %GameState{
      status: :playing,
      players: [john, mark],
      moves_played: [],
    }

    turn_moves = %{
      john.id => Move.new(:special_beam, mark.id),
      mark.id => Move.new(:disk, john.id)
    }

    game_after_process = %GameState{
      status: :done,
      players: [
        %Player{john | charges: 0},
        %Player{mark | charges: 0, state: :dead},
      ],
      moves_played: [turn_moves],
      winner: john.id
    }

    assert GameState.process_turn(game, turn_moves) == game_after_process
  end

  test "two players, reflect kills attacker" do
    john = %Player{
      name: "John",
      id: "1",
      charges: 5,
      state: :alive
    }
    mark = %Player{
      name: "Mark",
      id: "2",
      charges: 5,
      state: :alive
    }

    game = %GameState{
      status: :playing,
      players: [john, mark],
      moves_played: [],
    }

    turn_moves = %{
      john.id => Move.new(:special_beam, mark.id),
      mark.id => Move.new(:reflect)
    }

    game_after_process = %GameState{
      status: :done,
      players: [
        %Player{john | charges: 0, state: :dead},
        %Player{mark | charges: 1},
      ],
      moves_played: [turn_moves],
      winner: mark.id
    }

    assert GameState.process_turn(game, turn_moves) == game_after_process
  end

  test "four players, all kill each other" do
    john = %Player{
      name: "John",
      id: "1",
      charges: 3,
      state: :alive
    }
    mark = %Player{
      name: "Mark",
      id: "2",
      charges: 2,
      state: :alive
    }
    paul = %Player{
      name: "Paul",
      id: "3",
      charges: 2
    }
    rosa = %Player{
      name: "Rosa",
      id: "4",
      charges: 4
    }

    game = %GameState{
      status: :playing,
      players: [john, mark, paul, rosa],
      moves_played: [],
    }

    turn_moves = %{
      john.id => Move.new(:kamehameha, mark.id),
      mark.id => Move.new(:kamehameha, paul.id),
      paul.id => Move.new(:kamehameha, rosa.id),
      rosa.id => Move.new(:kamehameha, john.id),
    }

    game_after_process = %GameState{
      status: :done,
      players: [
        %Player{john | charges: 0, state: :dead},
        %Player{mark | charges: 0, state: :dead},
        %Player{paul | charges: 0, state: :dead},
        %Player{rosa | charges: 0, state: :dead},
      ],
      moves_played: [turn_moves],
      winner: nil # No winner b/c all dead
    }

    assert GameState.process_turn(game, turn_moves) == game_after_process
  end

  test "four players, one spirit bombs to win" do
    john = %Player{
      name: "John",
      id: "1",
      charges: 10,
      state: :alive
    }
    mark = %Player{
      name: "Mark",
      id: "2",
      charges: 2,
      state: :alive
    }
    paul = %Player{
      name: "Paul",
      id: "3",
      charges: 2
    }
    rosa = %Player{
      name: "Rosa",
      id: "4",
      charges: 4
    }

    game = %GameState{
      status: :playing,
      players: [john, mark, paul, rosa],
      moves_played: [],
    }

    turn_moves = %{
      john.id => Move.new(:spirit_bomb),
      mark.id => Move.new(:kamehameha, paul.id),
      paul.id => Move.new(:kamehameha, rosa.id),
      rosa.id => Move.new(:kamehameha, john.id),
    }

    game_after_process = %GameState{
      status: :done,
      players: [
        %Player{john | charges: 0},
        %Player{mark | charges: 0, state: :dead},
        %Player{paul | charges: 0, state: :dead},
        %Player{rosa | charges: 0, state: :dead},
      ],
      moves_played: [turn_moves],
      winner: john.id
    }

    assert GameState.process_turn(game, turn_moves) == game_after_process
  end

  test "four players, two spirit bombs, everyone's dead, no winner" do
    john = %Player{
      name: "John",
      id: "1",
      charges: 10,
      state: :alive
    }
    mark = %Player{
      name: "Mark",
      id: "2",
      charges: 10,
      state: :alive
    }
    paul = %Player{
      name: "Paul",
      id: "3",
      charges: 2
    }
    rosa = %Player{
      name: "Rosa",
      id: "4",
      charges: 4
    }

    game = %GameState{
      status: :playing,
      players: [john, mark, paul, rosa],
      moves_played: [],
    }

    turn_moves = %{
      john.id => Move.new(:spirit_bomb),
      mark.id => Move.new(:spirit_bomb),
      paul.id => Move.new(:kamehameha, rosa.id),
      rosa.id => Move.new(:kamehameha, john.id),
    }

    game_after_process = %GameState{
      status: :done,
      players: [
        %Player{john | charges: 0, state: :dead},
        %Player{mark | charges: 0, state: :dead},
        %Player{paul | charges: 0, state: :dead},
        %Player{rosa | charges: 0, state: :dead},
      ],
      moves_played: [turn_moves],
      winner: nil
    }

    assert GameState.process_turn(game, turn_moves) == game_after_process
  end
end
