defmodule Dragonball.GameRoundTest do
  use ExUnit.Case, async: true
  alias Dragonball.GameRound
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

    round = %GameRound{
      status: :playing,
      players: [john, mark],
      previous_turns: [],
    }

    turn_moves = %{
      john.id => Move.new(:kamehameha, mark.id),
      mark.id => Move.new(:charge)
    }

    round_after_process = %GameRound{
      status: :done,
      players: [
        %Player{john | charges: 0},
        %Player{mark | charges: 0, state: :dead},
      ],
      previous_turns: [turn_moves],
      winner: john.id
    }

    assert GameRound.process_turn(round, turn_moves) == round_after_process
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

    round = %GameRound{
      status: :playing,
      players: [john, mark],
      previous_turns: [],
    }

    turn_moves = %{
      john.id => Move.new(:kamehameha, mark.id),
      mark.id => Move.new(:block)
    }

    round_after_process = %GameRound{
      status: :playing,
      players: [
        %Player{john | charges: 0},
        mark,
      ],
      previous_turns: [turn_moves],
    }

    assert GameRound.process_turn(round, turn_moves) == round_after_process
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

    round = %GameRound{
      status: :playing,
      players: [john, mark],
      previous_turns: [],
    }

    turn_moves = %{
      john.id => Move.new(:kamehameha, mark.id),
      mark.id => Move.new(:disk, john.id)
    }

    round_after_process = %GameRound{
      status: :done,
      players: [
        %Player{john | charges: 0, state: :dead},
        %Player{mark | charges: 0},
      ],
      previous_turns: [turn_moves],
      winner: mark.id
    }

    assert GameRound.process_turn(round, turn_moves) == round_after_process
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

    round = %GameRound{
      status: :playing,
      players: [john, mark],
      previous_turns: [],
    }

    turn_moves = %{
      john.id => Move.new(:special_beam, mark.id),
      mark.id => Move.new(:disk, john.id)
    }

    round_after_process = %GameRound{
      status: :done,
      players: [
        %Player{john | charges: 0},
        %Player{mark | charges: 0, state: :dead},
      ],
      previous_turns: [turn_moves],
      winner: john.id
    }

    assert GameRound.process_turn(round, turn_moves) == round_after_process
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

    round = %GameRound{
      status: :playing,
      players: [john, mark],
      previous_turns: [],
    }

    turn_moves = %{
      john.id => Move.new(:special_beam, mark.id),
      mark.id => Move.new(:reflect)
    }

    round_after_process = %GameRound{
      status: :done,
      players: [
        %Player{john | charges: 0, state: :dead},
        %Player{mark | charges: 1},
      ],
      previous_turns: [turn_moves],
      winner: mark.id
    }

    assert GameRound.process_turn(round, turn_moves) == round_after_process
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

    round = %GameRound{
      status: :playing,
      players: [john, mark, paul, rosa],
      previous_turns: [],
    }

    turn_moves = %{
      john.id => Move.new(:kamehameha, mark.id),
      mark.id => Move.new(:kamehameha, paul.id),
      paul.id => Move.new(:kamehameha, rosa.id),
      rosa.id => Move.new(:kamehameha, john.id),
    }

    round_after_process = %GameRound{
      status: :done,
      players: [
        %Player{john | charges: 0, state: :dead},
        %Player{mark | charges: 0, state: :dead},
        %Player{paul | charges: 0, state: :dead},
        %Player{rosa | charges: 0, state: :dead},
      ],
      previous_turns: [turn_moves],
      winner: nil # No winner b/c all dead
    }

    assert GameRound.process_turn(round, turn_moves) == round_after_process
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

    round = %GameRound{
      status: :playing,
      players: [john, mark, paul, rosa],
      previous_turns: [],
    }

    turn_moves = %{
      john.id => Move.new(:spirit_bomb),
      mark.id => Move.new(:kamehameha, paul.id),
      paul.id => Move.new(:kamehameha, rosa.id),
      rosa.id => Move.new(:kamehameha, john.id),
    }

    round_after_process = %GameRound{
      status: :done,
      players: [
        %Player{john | charges: 0},
        %Player{mark | charges: 0, state: :dead},
        %Player{paul | charges: 0, state: :dead},
        %Player{rosa | charges: 0, state: :dead},
      ],
      previous_turns: [turn_moves],
      winner: john.id
    }

    assert GameRound.process_turn(round, turn_moves) == round_after_process
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

    round = %GameRound{
      status: :playing,
      players: [john, mark, paul, rosa],
      previous_turns: [],
    }

    turn_moves = %{
      john.id => Move.new(:spirit_bomb),
      mark.id => Move.new(:spirit_bomb),
      paul.id => Move.new(:kamehameha, rosa.id),
      rosa.id => Move.new(:kamehameha, john.id),
    }

    round_after_process = %GameRound{
      status: :done,
      players: [
        %Player{john | charges: 0, state: :dead},
        %Player{mark | charges: 0, state: :dead},
        %Player{paul | charges: 0, state: :dead},
        %Player{rosa | charges: 0, state: :dead},
      ],
      previous_turns: [turn_moves],
      winner: nil
    }

    assert GameRound.process_turn(round, turn_moves) == round_after_process
  end
end
