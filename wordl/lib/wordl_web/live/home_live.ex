defmodule WordlWeb.HomeLive do
  use WordlWeb, :live_view

  alias Wordl.Games
  alias Wordl.Games.Play
  alias WordlWeb.GuessBoard

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Games.subscribe()

    {:ok,
     socket
     |> assign(:page_title, "Wordl")
     |> assign(:player_name, "")
     |> load_board()}
  end

  @impl true
  def handle_event("generate", _params, socket) do
    case Games.generate_puzzle() do
      {:ok, _puzzle} ->
        {:noreply, put_flash(load_board(socket), :info, "A new secret word is ready.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not generate a word.")}
    end
  end

  def handle_event("validate_player", %{"player" => %{"name" => name}}, socket) do
    {:noreply, assign(socket, :player_name, name)}
  end

  def handle_event("start", %{"player" => %{"name" => name}}, socket) do
    name = String.trim(name)

    cond do
      name == "" ->
        {:noreply, put_flash(socket, :error, "Enter a player name to start.")}

      is_nil(socket.assigns.puzzle) ->
        {:noreply, put_flash(socket, :error, "Generate a secret word first.")}

      true ->
        case Games.start_play(socket.assigns.puzzle, name) do
          {:ok, play} ->
            {:noreply, push_navigate(socket, to: ~p"/play/#{play.id}")}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not start the game.")}
        end
    end
  end

  @impl true
  def handle_info({:puzzle_created, _puzzle}, socket) do
    {:noreply, load_board(socket)}
  end

  def handle_info({:play_updated, _play}, socket) do
    {:noreply, load_board(socket)}
  end

  defp load_board(socket) do
    puzzle = Games.current_puzzle()

    socket
    |> assign(:puzzle, puzzle)
    |> assign(:past_puzzles, Games.list_past_puzzles())
    |> assign(:completed, if(puzzle, do: Games.completed_plays(puzzle), else: []))
    |> assign(:active, if(puzzle, do: Games.active_plays(puzzle), else: []))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-10">
        <header class="text-center space-y-2">
          <p class="text-sm tracking-[0.4em] uppercase text-zinc-500">New York Times inspired</p>
          <h1 class="text-5xl font-black tracking-tight">WORDL</h1>
          <p class="text-base-content/70">
            One shared secret. Everyone guesses. Green, yellow, and gray — just like Wordle.
          </p>
        </header>

        <section class="card bg-base-200 shadow-sm">
          <div class="card-body gap-4">
            <h2 class="card-title">Play</h2>
            <p :if={@puzzle} class="text-sm text-base-content/70">
              A five-letter secret is live. Enter your name and start guessing.
            </p>
            <p :if={is_nil(@puzzle)} class="text-sm text-base-content/70">
              No secret yet. Generate one, then start playing.
            </p>

            <div class="flex flex-wrap gap-2">
              <button type="button" class="btn btn-outline" phx-click="generate">
                Generate new secret word
              </button>
            </div>

            <.form
              for={%{}}
              as={:player}
              phx-change="validate_player"
              phx-submit="start"
              id="player-form"
              class="flex flex-col sm:flex-row gap-2"
            >
              <input
                type="text"
                name="player[name]"
                value={@player_name}
                maxlength="40"
                placeholder="Your name"
                class="input input-bordered w-full"
                autocomplete="nickname"
              />
              <button type="submit" class="btn btn-primary">Start the game</button>
            </.form>
          </div>
        </section>

        <section :if={@puzzle} class="grid gap-6 md:grid-cols-2">
          <div class="space-y-3">
            <h2 class="text-xl font-semibold">Finished this word</h2>
            <p :if={@completed == []} class="text-sm text-base-content/60">
              Nobody has finished yet.
            </p>
            <ul class="space-y-3">
              <li :for={play <- @completed} class="rounded-box border border-base-300 p-3 space-y-2">
                <div class="flex justify-between text-sm">
                  <span class="font-medium">{play.player_name}</span>
                  <span>{tries_label(play)}</span>
                </div>
                <GuessBoard.board guesses={play.guesses} secret={@puzzle.secret} compact />
              </li>
            </ul>
          </div>

          <div class="space-y-3">
            <h2 class="text-xl font-semibold">Actively playing</h2>
            <p :if={@active == []} class="text-sm text-base-content/60">No one is mid-game.</p>
            <ul class="space-y-3">
              <li :for={play <- @active} class="rounded-box border border-base-300 p-3 space-y-2">
                <div class="flex justify-between text-sm">
                  <span class="font-medium">{play.player_name}</span>
                  <span>{length(play.guesses)} suggestion(s)</span>
                </div>
                <GuessBoard.board guesses={play.guesses} secret={@puzzle.secret} compact />
              </li>
            </ul>
          </div>
        </section>

        <section class="space-y-4">
          <h2 class="text-xl font-semibold">Past words</h2>
          <p :if={@past_puzzles == []} class="text-sm text-base-content/60">
            History will show here after you generate another secret.
          </p>
          <article
            :for={puzzle <- @past_puzzles}
            class="rounded-box border border-base-300 p-4 space-y-4"
          >
            <div class="flex items-center justify-between">
              <h3 class="font-mono text-2xl tracking-widest uppercase">{puzzle.secret}</h3>
              <span class="text-xs text-base-content/60">
                {Calendar.strftime(puzzle.inserted_at, "%b %d, %Y %H:%M")}
              </span>
            </div>
            <p :if={puzzle.plays == []} class="text-sm text-base-content/60">
              No one played this word.
            </p>
            <div :for={play <- Enum.sort_by(puzzle.plays, & &1.player_name)} class="space-y-2">
              <div class="flex justify-between text-sm">
                <span class="font-medium">{play.player_name}</span>
                <span>Score: {score_label(play)}</span>
              </div>
              <GuessBoard.board guesses={play.guesses} secret={puzzle.secret} compact />
            </div>
          </article>
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp tries_label(%Play{status: "won"} = play), do: "#{Play.guess_count(play)} tries"
  defp tries_label(%Play{status: "lost"}), do: "did not solve"

  defp score_label(%Play{status: "won"} = play),
    do: "#{Play.guess_count(play)}/#{Play.max_guesses()}"

  defp score_label(%Play{status: "lost"}), do: "X/#{Play.max_guesses()}"
  defp score_label(%Play{} = play), do: "#{Play.guess_count(play)} in progress"
end
