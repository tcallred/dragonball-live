defmodule Dragonball.GameState do
  alias Dragonball.Player
  alias Dragonball.GameRound
  alias Dragonball.Move

  alias __MODULE__

  defstruct code: "",
            status: :setup,
            players: [],
            current_round: nil,
            current_turn_moves: %{},
            previous_rounds: [],
            score_limit: 0,
            scores: %{}

  @player_limit 6

  @type game_code_type :: String.t()

  @type score_type :: non_neg_integer()

  @type t :: %GameState{
          code: game_code_type(),
          status: :setup | :playing | :done,
          players: [Player.t()],
          current_round: GameRound.t(),
          current_turn_moves: GameRound.turn_moves(),
          previous_rounds: [GameRound.t()],
          score_limit: score_type(),
          scores: %{Player.id_type() => score_type()}
        }

  def new(score_limit, player, code \\ "") do
    %GameState{score_limit: score_limit, code: code, players: [player]}
  end

  def join_game(%GameState{players: players} = state, player) do
    if Enum.count(players) < @player_limit do
      {:ok, %GameState{state | players: [player | players]}}
    else
      {:error, "Player limit reached"}
    end
  end

  @spec start(t()) :: {:ok, t()} | {:error, String.t()}
  def start(%GameState{status: :playing}), do: {:error, "Game is already started"}

  def start(%GameState{status: :done}), do: {:error, "Game is done"}

  def start(%GameState{status: :setup, players: []}), do: {:error, "Not enough players"}

  def start(%GameState{status: :setup, players: [_p1 | _players]}) do
    {:error, "Not enough players"}
  end

  def start(%GameState{status: :setup, players: players} = state) do
    scores =
      players
      |> Enum.map(&{&1.id, 0})
      |> Map.new()

    {:ok, %GameState{state | status: :playing, scores: scores}}
  end

  @spec check_for_winner(t()) :: Player.id_type() | :not_found
  def check_for_winner(%GameState{scores: scores, score_limit: score_limit}) do
    case Enum.find(scores, fn {_, player_score} -> player_score == score_limit end) do
      {id, _} -> id
      nil -> :not_found
    end
  end

  @spec start_new_round(t()) :: {:ok, t()} | {:error, String.t()}
  def start_new_round(%GameState{status: :playing} = state) do
    prev_rounds =
      if state.current_round do
        [state.current_round | state.previous_rounds]
      else
        state.previous_rounds
      end

    round = GameRound.new(state.players)
    moves = default_player_moves(state)

    {:ok,
     %GameState{
       state
       | current_round: round,
         current_turn_moves: moves,
         previous_rounds: prev_rounds
     }}
  end

  def start_new_round(%GameState{status: _status}), do: {:error, "Game is not playing"}

  @spec play_move(t(), Player.id_type(), Move.t()) :: {:ok, t()} | {:error, String.t()}
  def play_move(%GameState{status: :playing, current_turn_moves: moves} = state, player_id, move) do
    {:ok, %GameState{state | current_turn_moves: Map.replace!(moves, player_id, move)}}
  end

  def play_move(%GameState{status: _status}, _player_id, _move),
    do: {:error, "Game is not playing"}

  def process_turn(
        %GameState{status: :playing, current_turn_moves: moves, current_round: round} = state
      ) do
    new_round = GameRound.process_turn(round, moves)

    scores =
      case {new_round.status, new_round.winner} do
        {:done, player_id} -> Map.update!(state.scores, player_id, &(&1 + 1))
        {_, _} -> state.scores
      end

    new_state = %GameState{
      state
      | current_round: new_round,
        scores: scores,
        previous_rounds: [round | state.previous_rounds]
    }

    {:ok, new_state}
  end

  def process_turn(%GameState{status: _status}), do: {:error, "Game is not playing"}

  def reset_turn_moves(state) do
    %GameState{state | current_turn_moves: default_player_moves(state)}
  end

  @spec default_player_moves(t()) :: GameRound.player_moves()
  defp default_player_moves(%GameState{players: players}) do
    players
    |> Enum.map(&{&1.id, Move.new(:charge)})
    |> Map.new()
  end
end
