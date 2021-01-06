require 'securerandom'
require 'base64'
require 'digest'

module PKCE
  def generate_code_verifier
    SecureRandom.alphanumeric(43)
  end

  def generate_code_challenge(code_verifier)
    Base64.urlsafe_encode64(
      Digest::SHA256.digest(code_verifier)
    ).gsub(/[\=\/\+]+/, '')
  end

  def compare_code_verifier(code_verifier, code_challenge)
    generate_code_challenge(code_verifier) == code_challenge
  end
end
