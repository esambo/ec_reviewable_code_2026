defmodule WordlWeb.GuessBoard do
  use Phoenix.Component

  alias Wordl.Score

  attr :guesses, :list, required: true
  attr :secret, :string, required: true
  attr :max_rows, :integer, default: 6
  attr :current, :string, default: ""
  attr :compact, :boolean, default: false

  def board(assigns) do
    rows = board_rows(assigns)
    assigns = assign(assigns, :rows, rows)

    ~H"""
    <div class={["flex flex-col gap-1", @compact && "gap-0.5"]}>
      <div :for={row <- @rows} class="flex gap-1 justify-center">
        <.tile
          :for={{letter, color} <- row}
          letter={letter}
          color={color}
          compact={@compact}
        />
      </div>
    </div>
    """
  end

  attr :letter, :string, required: true
  attr :color, :atom, required: true
  attr :compact, :boolean, default: false

  def tile(assigns) do
    ~H"""
    <div class={[
      "flex items-center justify-center font-bold uppercase border-2",
      @compact && "size-6 text-xs",
      not @compact && "size-12 text-xl sm:size-14",
      tile_class(@color)
    ]}>
      {@letter}
    </div>
    """
  end

  def colored_guesses(guesses, secret) do
    Enum.map(guesses, &Score.color(&1, secret))
  end

  defp board_rows(%{guesses: guesses, secret: secret, current: current, max_rows: max_rows}) do
    colored = colored_guesses(guesses, secret)
    current_row = current_tiles(current)
    empties = max_rows - length(colored) - if(current_row, do: 1, else: 0)

    rows = colored ++ List.wrap(current_row) ++ List.duplicate(empty_row(), max(empties, 0))
    Enum.take(rows, max_rows)
  end

  defp current_tiles(""), do: nil
  defp current_tiles(nil), do: nil

  defp current_tiles(current) do
    letters = current |> String.upcase() |> String.graphemes() |> Enum.take(5)
    padded = letters ++ List.duplicate("", 5 - length(letters))
    Enum.map(padded, &{&1, :empty})
  end

  defp empty_row, do: List.duplicate({"", :empty}, 5)

  defp tile_class(:green), do: "bg-green-600 border-green-600 text-white"
  defp tile_class(:yellow), do: "bg-yellow-500 border-yellow-500 text-white"
  defp tile_class(:gray), do: "bg-zinc-500 border-zinc-500 text-white"
  defp tile_class(:empty), do: "bg-transparent border-zinc-400 text-base-content"
end
