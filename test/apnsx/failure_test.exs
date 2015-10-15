defmodule APNSx.FailureTest do
  use ExUnit.Case
  alias APNSx.Failure

  test "get failure struct for code and id" do
    failure = Failure.build(1, 42)
    assert 1 == failure.code
    assert "Processing error" == failure.reason
    assert 42 == failure.id
  end

  test "holds description unknown status code" do
    assert "None (unknown)" == Failure.build(-1, 42).reason
  end

  test "implements String.Chars" do
    failure = %Failure{code: 1, reason: "reason", id: 42}
    assert "reason" == to_string(failure)
  end
end
