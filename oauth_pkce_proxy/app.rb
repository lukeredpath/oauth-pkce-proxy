require 'sinatra/reloader'
require 'sinatra/json'
require 'httparty'

require_relative 'pkce'

module OauthPkceProxy
  Provider = Struct.new(
    :client_secret,
    :authorize_url,
    :access_token_url,
    keyword_init: true
  )

  class App < Sinatra::Base
    include PKCE

    attr_reader :provider
    attr_reader :challenge_store

    def initialize(app = nil, provider: nil, challenge_store:)
      super app
      @provider = provider
      @challenge_store = challenge_store
    end

    configure :development do
      register Sinatra::Reloader
    end

    enable :sessions

    get '/oauth/authorize' do
      if params[:code_challenge].nil?
        halt 400, 'code_challenge param was missing'
      end

      session[:original_redirect_uri] = params[:redirect_uri]
      session[:code_challenge] = params[:code_challenge]

      redirect to("#{provider.authorize_url}?#{authorize_params(request, params)}")
    end

    get '/oauth/code' do
      challenge_store.set(params[:code], session[:code_challenge])

      redirect to(session[:original_redirect_uri] + "?code=#{params[:code]}")
    end

    post '/oauth/access_token' do
      if params[:code_verifier].nil?
        halt 400, 'code_verifier param was missing'
      end

      if params[:code].nil?
        halt 400, 'code param was missing'
      end

      if compare_code_verifier(params[:code_verifier], challenge_store.get(params[:code]))
        exchange_code_for_access_token(params)
      else
        halt 400, "code_verifier does not match code_challenge for this code"
      end
    end

    get '/example_client_code_handler' do
      "Success - the code was: #{params[:code]}"
    end

    private

    def authorize_params(request, params)
      forwarding_params = params
      forwarding_params['redirect_uri'] = "#{request.base_url}/oauth/code"
      forwarding_params.map { |k, v| "#{k}=#{v}" }.join("&")
    end

    def exchange_code_for_access_token(params)
      to_rack_response HTTParty.post(
        provider.access_token_url,
        query: params.merge(client_secret: provider.client_secret)
      )
    end

    def to_rack_response(response)
      [response.code, {}, response.body]
    end
  end
end
