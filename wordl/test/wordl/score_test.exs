defmodule Wordl.ScoreTest do
  use ExUnit.Case, async: true

  alias Wordl.Score

  test "marks exact matches green" do
    assert Score.color("crane", "crane") == [
             {"C", :green},
             {"R", :green},
             {"A", :green},
             {"N", :green},
             {"E", :green}
           ]
  end

  test "marks absent letters gray and present letters yellow" do
    assert Score.color("slate", "crane") == [
             {"S", :gray},
             {"L", :gray},
             {"A", :green},
             {"T", :gray},
             {"E", :green}
           ]
  end

  test "does not over-mark duplicate letters as yellow" do
    assert Score.color("hello", "world") == [
             {"H", :gray},
             {"E", :gray},
             {"L", :gray},
             {"L", :green},
             {"O", :yellow}
           ]
  end
end
