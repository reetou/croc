defmodule Croc.Helpers do
  use Timex

  def duration(%DateTime{} = dt) do
    DateTime.diff(DateTime.utc_now(), dt)
    |> Timex.Duration.from_seconds()
    |> Timex.format_duration(:humanized)
  end
end
