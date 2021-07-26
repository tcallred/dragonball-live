defmodule Dragonball.Move do
  alias Dragonball.Player
  alias __MODULE__

  @type dragonball_move ::
          :charge
          | :block
          | :kamehameha
          | :disk
          | :super_saiyan
          | :reflect
          | :special_beam
          | :spirit_bomb

  @type t :: %Move{
          move_type: dragonball_move(),
          target: nil | Player.id_type()
        }

  defstruct move_type: :charge,
            target: nil

  def new(move_type, target \\ nil) do
    %Move{
      move_type: move_type,
      target: target
    }
  end

  def cost_of(%__MODULE__{move_type: move_type}) do
    case move_type do
      :charge -> 0
      :block -> 0
      :kamehameha -> 1
      :disk -> 2
      :super_saiyan -> 3
      :reflect -> 4
      :special_beam -> 5
      :spirit_bomb -> 10
    end
  end
end
