#!/usr/bin/env ruby
require_relative '../oauth_pkce_proxy/pkce'

include PKCE

code_verifier = generate_code_verifier

puts "Verifier: #{code_verifier}"
puts "Challenge: #{generate_code_challenge(code_verifier)}"
