defmodule Dragonball.Player do
  alias Dragonball.Move
  alias __MODULE__

  defstruct id: "",
            name: "",
            charges: 0,
            state: :alive

  @type id_type :: String.t()

  @type t :: %Player{
          id: id_type(),
          name: String.t(),
          charges: Integer.t(),
          state: :alive | :super | :dead
        }

  def new(name) do
    # TODO Make an id
    %Player{name: name}
  end

  def is_alive?(%Player{state: state}) do
    state == :alive || state == :super
  end

  def kill(%Player{state: state} = player) do
    case state do
      :alive ->
        %Player{player | state: :dead, charges: 0}

      :super ->
        %Player{player | state: :alive}
    end
  end

  def can_do_move?(player, move) do
    is_alive?(player) && has_charges_for?(player, move)
  end

  def has_charges_for?(%Player{charges: charges}, move) do
    charges >= Move.cost_of(move)
  end

  def move_completed(%Player{charges: charges} = player, %Move{move_type: move_type} = move) do
    case move_type do
      :charge ->
        charge(player)

      :super_saiyan ->
        %Player{player | state: :super, charges: charges - Move.cost_of(move)}

      _ ->
        %Player{player | charges: charges - Move.cost_of(move)}
    end
  end

  defp charge(%Player{charges: charges, state: state} = player) do
    increment =
      case state do
        :alive -> 1
        :super -> 2
      end

    %Player{player | charges: charges + increment}
  end
end
