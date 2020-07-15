require 'rubygems'
require 'bundler'

Bundler.require

require 'dotenv/load'

require_relative 'oauth_pkce_proxy/app'

github = OauthPkceProxy::Provider.new(
  client_secret: ENV['GITHUB_OAUTH_CLIENT_SECRET'],
  authorize_url: 'https://github.com/login/oauth/authorize',
  access_token_url: 'https://github.com/login/oauth/access_token'
)

run OauthPkceProxy::App.new(provider: github)
