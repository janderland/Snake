defmodule Snake.Scenes.GameOver do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives,
    only: [text: 3, update_opts: 2]


  @text_opts [
    id: :gameover,
    fill: :white,
    text_align: :center
  ]

  @graph Graph.build(
    font: :roboto,
    font_size: 36,
    clean_color: :black)
  |> text("Game Over!", @text_opts)

  @game_scene Snake.Scenes.Game



  def init(score, opts) do
    Process.send_after(self(), :end_cooldown, 2000)

    viewport = opts[:viewport]

    state = %{
      graph:
        @graph
        |> center_gameover_text(viewport)
        |> push_graph,
      viewport: viewport,
      on_cooldown: true,
      score: score
    }

    {:ok, state}
  end

  def handle_info(:end_cooldown, state),
    do: {
      :noreply,
      %{state |
        on_cooldown: false,
        graph:
          state.graph
          |> display_score(state.score)
          |> center_gameover_text(state.viewport)
          |> push_graph
      }
    }

  defp center_gameover_text(graph, viewport),
    do: Graph.modify(
      graph,
      :gameover,
      &translate_to_center(&1, viewport))

  defp display_score(graph, score),
    do: Graph.modify(
      graph,
      :gameover,
      &text(
        &1,
        """
        Game Over!
        You scored #{score}.
        Press any key to try again.
        """,
        @text_opts))

  defp translate_to_center(node, viewport),
    do: update_opts(
      node,
      translate: viewport_center(viewport))

  defp viewport_center(viewport) do
    {:ok, %ViewPort.Status{
      size: {
        vp_width,
        vp_height
      }
    }} = ViewPort.info(viewport)

    {vp_width / 2, vp_height / 2}
  end



  def handle_input({:key, _}, _context, %{on_cooldown: false} = state) do
    restart_game(state)
    {:noreply, state}
  end

  def handle_input(_input, _context, state),
    do: {:noreply, state}

  defp restart_game(%{viewport: viewport}),
    do: ViewPort.set_root(viewport, {@game_scene, nil})
end
