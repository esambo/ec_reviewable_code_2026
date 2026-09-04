defmodule WordlWeb.PlayLive do
  use WordlWeb, :live_view

  alias Wordl.Games
  alias Wordl.Games.Play
  alias WordlWeb.GuessBoard

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket), do: Games.subscribe()

    play = Games.get_play!(id)

    {:ok,
     socket
     |> assign(:page_title, "Play Wordl")
     |> assign(:draft, "")
     |> assign(:draft_key, 0)
     |> assign_play(play)}
  end

  @impl true
  def handle_event("update_draft", %{"guess" => %{"word" => word}}, socket) do
    {:noreply, assign(socket, :draft, sanitize_draft(word))}
  end

  def handle_event("submit_guess", %{"guess" => %{"word" => word}}, socket) do
    submit(socket, word)
  end

  def handle_event("submit_guess", _params, socket) do
    submit(socket, socket.assigns.draft)
  end

  @impl true
  def handle_info({:play_updated, play}, socket) do
    current = socket.assigns.play

    socket =
      if play.id == current.id do
        assign_play(socket, play)
      else
        reload_puzzle(socket)
      end

    {:noreply, socket}
  end

  def handle_info({:puzzle_created, _puzzle}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "A new secret was generated. This board is now history.")
     |> push_navigate(to: ~p"/")}
  end

  defp submit(socket, word) do
    case Games.submit_guess(socket.assigns.play, word) do
      {:ok, play} ->
        {:noreply,
         socket
         |> assign(:draft, "")
         |> update(:draft_key, &(&1 + 1))
         |> assign_play(play)
         |> maybe_flash(play)}

      {:error, :invalid_length} ->
        {:noreply, put_flash(socket, :error, "Guesses must be five letters.")}

      {:error, :not_in_dictionary} ->
        {:noreply, put_flash(socket, :error, "That word is not in the dictionary.")}

      {:error, :already_guessed} ->
        {:noreply, put_flash(socket, :error, "You already tried that word.")}

      {:error, :game_over} ->
        {:noreply, put_flash(socket, :error, "This game is already finished.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not submit that guess.")}
    end
  end

  defp maybe_flash(socket, %Play{status: "won"}) do
    put_flash(socket, :info, "You got it!")
  end

  defp maybe_flash(socket, %Play{status: "lost"} = play) do
    put_flash(socket, :error, "Out of tries. The word was #{String.upcase(play.puzzle.secret)}.")
  end

  defp maybe_flash(socket, _play), do: socket

  defp assign_play(socket, play) do
    play = if Ecto.assoc_loaded?(play.puzzle), do: play, else: Games.get_play!(play.id)
    puzzle = Games.get_puzzle!(play.puzzle_id)

    socket
    |> assign(:play, %{play | puzzle: puzzle})
    |> assign(:puzzle, puzzle)
    |> assign(:completed, Games.completed_plays(puzzle))
    |> assign(:active, Games.active_plays(puzzle))
  end

  defp reload_puzzle(socket) do
    assign_play(socket, socket.assigns.play)
  end

  defp sanitize_draft(word) do
    word
    |> String.downcase()
    |> String.replace(~r/[^a-z]/, "")
    |> String.slice(0, 5)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="grid gap-8 lg:grid-cols-[1fr_16rem]">
        <section class="space-y-6">
          <div class="flex items-center justify-between">
            <.link navigate={~p"/"} class="link link-hover text-sm">← Lobby</.link>
            <p class="text-sm">Playing as <span class="font-semibold">{@play.player_name}</span></p>
          </div>

          <GuessBoard.board guesses={@play.guesses} secret={@puzzle.secret} current={@draft} />

          <div :if={@play.status == "playing"} class="space-y-3">
            <.form
              for={%{}}
              as={:guess}
              id="guess-form"
              phx-change="update_draft"
              phx-submit="submit_guess"
              class="flex gap-2"
            >
              <input
                id={"guess-word-#{@draft_key}"}
                type="text"
                name="guess[word]"
                value={@draft}
                maxlength="5"
                autocapitalize="none"
                autocomplete="off"
                spellcheck="false"
                placeholder="guess"
                class="input input-bordered font-mono tracking-[0.4em] uppercase text-center text-xl w-full"
              />
              <button class="btn btn-primary">Guess</button>
            </.form>
            <p class="text-center text-sm text-base-content/60">
              {Play.max_guesses() - length(@play.guesses)} tries left
            </p>
          </div>

          <p :if={@play.status == "won"} class="text-center font-semibold text-green-600">
            Solved in {length(@play.guesses)} {if length(@play.guesses) == 1, do: "try", else: "tries"}.
          </p>
          <p :if={@play.status == "lost"} class="text-center font-semibold">
            The secret was <span class="font-mono tracking-widest uppercase">{@puzzle.secret}</span>.
          </p>
        </section>

        <aside class="space-y-6">
          <div>
            <h2 class="font-semibold mb-2">Finished</h2>
            <ul class="space-y-1 text-sm">
              <li :for={play <- others(@completed, @play)} class="flex justify-between">
                <span>{play.player_name}</span>
                <span>{finished_label(play)}</span>
              </li>
              <li :if={others(@completed, @play) == []} class="text-base-content/60">None yet</li>
            </ul>
          </div>
          <div>
            <h2 class="font-semibold mb-2">Still playing</h2>
            <ul class="space-y-1 text-sm">
              <li :for={play <- others(@active, @play)} class="flex justify-between">
                <span>{play.player_name}</span>
                <span>{length(play.guesses)} guess(es)</span>
              </li>
              <li :if={others(@active, @play) == []} class="text-base-content/60">Just you</li>
            </ul>
          </div>
        </aside>
      </div>
    </Layouts.app>
    """
  end

  defp others(plays, current), do: Enum.reject(plays, &(&1.id == current.id))

  defp finished_label(%Play{status: "won"} = play), do: "#{Play.guess_count(play)} tries"
  defp finished_label(%Play{status: "lost"}), do: "X"
end
