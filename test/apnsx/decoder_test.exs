defmodule APNSx.DecoderTest do
  use ExUnit.Case, async: true
  alias APNSx.Decoder

  test "parses a failure" do
    failure = Decoder.to_failure(<<8, 1, 1, 1, 1, 1>>)
    assert 1 == failure.code
    assert 16843009 == failure.id
  end

  test "parses a feedback information for a device token" do
    feedback = Decoder.to_feedback(<<86, 31, 186, 101, 0, 32, 206, 139, 230, 39, 46, 67, 232, 85, 22, 3, 62, 36, 180, 194, 137, 34, 14, 237, 164, 135, 156, 71, 113, 96, 178, 84, 94, 149, 182, 139, 89, 105>>)
    assert 1444919909 == feedback.timestamp
    assert "CE8BE6272E43E85516033E24B4C289220EEDA4879C477160B2545E95B68B5969" == feedback.device_token
  end
end
