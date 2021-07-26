defmodule Dragonball.GameState do
  alias Dragonball.Player
  alias Dragonball.Move
  alias __MODULE__

  defstruct code: nil,
            status: :setup,
            players: [],
            connected_players: [],
            moves_played: [],
            winner: nil

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
    spirit_bombs =
      Enum.filter(round_moves, fn {_, move} -> move.move_type == :spirit_bomb end)
      |> Enum.map(fn {id, _} -> id end)

    players_to_kill =
      cond do
        Enum.count(spirit_bombs) > 1 ->
          Enum.map(state.players, & &1.id)

        Enum.count(spirit_bombs) == 1 ->
          Enum.map(state.players, & &1.id)
          |> Enum.filter(&(&1 not in spirit_bombs))

        true ->
          round_moves
          |> Enum.map(&player_killed_by(&1, round_moves))
          |> Enum.reject(&is_nil/1)
      end

    players =
      state.players
      |> Enum.map(&kill_player(&1, players_to_kill))
      |> Enum.map(&complete_player_move(&1, round_moves))

    still_alive = Enum.filter(players, &Player.is_alive?/1)

    winner = if Enum.count(still_alive) == 1, do: Enum.at(still_alive, 0).id

    next_status = if winner || Enum.count(still_alive) == 0, do: :done, else: state.status

    %GameState{
      state
      | players: players,
        moves_played: [round_moves | state.moves_played],
        winner: winner,
        status: next_status
    }
  end

  defp player_killed_by({player_id, %Move{move_type: move_type, target: target}}, round_moves) do
    case move_type do
      :kamehameha ->
        %Move{
          move_type: target_move_type,
          target: targets_target
        } = Map.fetch!(round_moves, target)

        case target_move_type do
          :kamehameha when targets_target == player_id ->
            nil

          mt when mt in [:charge, :kamehameha, :super_saiyan] ->
            target

          :reflect ->
            player_id

          _ ->
            nil
        end

      :disk ->
        %Move{
          move_type: target_move_type,
          target: targets_target
        } = Map.fetch!(round_moves, target)

        case target_move_type do
          :disk when targets_target == player_id ->
            nil

          mt when mt in [:charge, :kamehameha, :disk, :super_saiyan] ->
            target

          :reflect ->
            player_id

          _ ->
            nil
        end

      :special_beam ->
        %Move{
          move_type: target_move_type,
          target: targets_target
        } = Map.fetch!(round_moves, target)

        case target_move_type do
          :special_beam when targets_target == player_id ->
            nil

          mt when mt in [:charge, :block, :kamehameha, :disk, :super_saiyan, :special_beam] ->
            target

          :reflect ->
            player_id

          _ ->
            nil
        end

      _ ->
        nil
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

    if Player.can_do_move?(player, move) do
      Player.move_completed(player, move)
    else
      player
    end
  end
end
