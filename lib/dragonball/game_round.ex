defmodule Dragonball.GameRound do
  alias Dragonball.Player
  alias Dragonball.Move
  alias __MODULE__

  defstruct status: :playing,
            players: [],
            previous_turns: [],
            winner: nil

  @type turn_moves :: %{Player.id_type() => Move.t()}

  @type t :: %GameRound{
          status: :playing | :done,
          players: [Player.t()],
          previous_turns: [turn_moves()],
          winner: nil | Player.id_type()
        }

  def new(players) do
    %GameRound{players: players}
  end

  @spec process_turn(t(), turn_moves :: turn_moves()) :: t()
  def process_turn(round, turn_moves) do
    spirit_bombs =
      Enum.filter(turn_moves, fn {_, move} -> move.move_type == :spirit_bomb end)
      |> Enum.map(fn {id, _} -> id end)

    players_to_kill =
      cond do
        Enum.count(spirit_bombs) > 1 ->
          Enum.map(round.players, & &1.id)

        Enum.count(spirit_bombs) == 1 ->
          Enum.map(round.players, & &1.id)
          |> Enum.filter(&(&1 not in spirit_bombs))

        true ->
          turn_moves
          |> Enum.map(&player_killed_by(&1, turn_moves))
          |> Enum.reject(&is_nil/1)
      end

    players =
      round.players
      |> Enum.map(&kill_player(&1, players_to_kill))
      |> Enum.map(&complete_player_move(&1, turn_moves))

    still_alive = Enum.filter(players, &Player.is_alive?/1)

    winner = if Enum.count(still_alive) == 1, do: Enum.at(still_alive, 0).id

    next_status = if winner || Enum.count(still_alive) == 0, do: :done, else: round.status

    %GameRound{
      round
      | players: players,
        previous_turns: [turn_moves | round.previous_turns],
        winner: winner,
        status: next_status
    }
  end

  defp player_who_dies(player, _, _, :reflect, _) do
    player
  end

  defp player_who_dies(player, attack, target, target_move, targets_target)
       when targets_target == player do
    if Move.move_priority(attack) > Move.move_priority(target_move) do
      target
    else
      nil
    end
  end

  defp player_who_dies(_, :kamehameha, target, target_move, _)
       when target_move not in [:block, :reflect] do
    target
  end

  defp player_who_dies(_, :disk, target, target_move, _)
       when target_move not in [:block, :reflect] do
    target
  end

  defp player_who_dies(_, :special_beam, target, target_move, _)
       when target_move not in [:reflect] do
    target
  end

  defp player_who_dies(_, _, _, _, _) do
    nil
  end

  defp player_killed_by({_, %Move{move_type: _mt, target: nil}}, _) do
    nil
  end

  defp player_killed_by({player_id, %Move{move_type: move_type, target: target}}, turn_moves) do
    %Move{
      move_type: target_move_type,
      target: targets_target
    } = Map.fetch!(turn_moves, target)

    player_who_dies(player_id, move_type, target, target_move_type, targets_target)
  end

  defp kill_player(player, players_to_kill) do
    if player.id in players_to_kill do
      Player.kill(player)
    else
      player
    end
  end

  defp complete_player_move(player, turn_moves) do
    move = Map.fetch!(turn_moves, player.id)

    if Player.can_do_move?(player, move) do
      Player.move_completed(player, move)
    else
      player
    end
  end
end
