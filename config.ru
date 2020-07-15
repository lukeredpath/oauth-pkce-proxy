require 'rubygems'
require 'bundler'

Bundler.require

require 'dotenv/load'

require_relative 'oauth_pkce_proxy/app'

class InMemoryStore
  def initialize
    @data = {}
  end

  def get(key)
    @data[key]
  end

  def set(key, value)
    @data[key] = value
  end
end

github = OauthPkceProxy::Provider.new(
  client_secret: ENV['GITHUB_OAUTH_CLIENT_SECRET'],
  authorize_url: 'https://github.com/login/oauth/authorize',
  access_token_url: 'https://github.com/login/oauth/access_token'
)

run OauthPkceProxy::App.new(provider: github, challenge_store: InMemoryStore.new)
