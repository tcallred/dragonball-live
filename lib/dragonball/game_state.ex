defmodule Dragonball.GameState do
  alias Dragonball.Player
  alias Dragonball.Move
  alias __MODULE__

  defstruct [
    code: nil,
    status: :setup,
    players: [],
    connected_players: [],
    moves_played: [],
    winner: nil
  ]

  @type game_code :: String.t()

  @type round_moves :: %{Player.id_type() => Move.t()}

  @type t :: %GameState{
    code: nil | game_code(),
    status: :setup | :playing | :done,
    players: [Player.t()],
    connected_players: [Player.id_type()],
    moves_played: [round_moves()],
    winner: nil | Player.id_type()
  }

  def start_game(state) do
    %GameState{state | status: :playing}
  end

  def add_player(state, player) do
    %GameState{state | players: [player | state.players]}
  end

  @spec process_round(t, round_moves :: round_moves()) :: t
  def process_round(state, round_moves) do
    spirit_bomb =
      Enum.find(round_moves, fn {_, move} -> move.move_type == :spirit_bomb end)

    players_to_kill =
      if spirit_bomb do
        round_moves
        |> Enum.map(fn {player_id, _} -> player_id)
        |> Enum.filter(&(&1 != Tuple.elem(spirit_bomb, 0)))

      else
        round_moves
        |> Enum.map(&(player_killed_by(&1, round_moves)))
        |> Enum.reject(&is_nil/1)

      end

    players =
      state.players
      |> Enum.map(& kill_player(&1, players_to_kill))
      |> Enum.map(& complete_player_move(&1, round_moves))

    still_alive =
      Enum.filter(players, &Player.is_alive?/1)

    winner =
      if Enum.count(still_alive) == 1, do: Enum.at(still_alive, 0)

    next_status =
      if winner, do: :done else: state.status

    %GameState{
      state |
      players: players,
      moves_played: [round_moves | state.moves_played],
      winner: winner,
      status: next_status
    }
  end

  defp player_killed_by({player_id, %Move{move_type: move_type, target: target}}, round_moves) do
    case move_type do
      :kamehameha ->
        %Move{move_type: target_move_type} = Map.fetch!(round_moves, target)
        cond do
          target_move_type in [:charge, :super_saiyan] -> target
          target_move_type == :reflect -> player_id
        end

      :disk ->
        %Move{move_type: target_move_type} = Map.fetch!(round_moves, target)
        cond do
          target_move_type in [:charge, :kamehameha, :super_saiyan], do: target
          target_move_type == :reflect -> player_id
        end

      :special_beam ->
        %Move{move_type: target_move_type} = Map.fetch!(round_moves, target)
        cond do
          target_move_type in [:charge, :block, :kamehameha, :disk, :super_saiyan], do: target
          target_move_type == :reflect -> player_id
        end
    end
  end

  defp kill_player(player, players_to_kill) do
    if player.id in players_to_kill do
      Player.kill(player)
    else
      player
    end
  end

  defp complete_player_move(player, round_moves) do
    move = Map.fetch!(round_moves, player.id)
    if Player.can_do_move?(player move) do
      Player.move_completed(player, move)
    else
      player
    end
  end

end
