require 'test_helper'
require 'pkce'

class PKCETest < Minitest::Test
  include PKCE

  def test_code_verifier
    assert_equal 43, generate_code_verifier.length
  end

  def test_code_verifier_challenge_comparison
    verifier = "kM83K571n5KFW9u29Xu2qSqgoUwep4I2jZw8FGZg4Yr"
    challenge = "_L61IKiv3U5wOqdQRpuxuPysCbxSFfrkC5JW3OkIY_4"

    assert compare_code_verifier(verifier, challenge)
  end
end
