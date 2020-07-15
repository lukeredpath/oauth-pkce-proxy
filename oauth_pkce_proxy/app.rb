require 'sinatra/reloader'
require 'sinatra/json'
require 'httparty'

module OauthPkceProxy
  Provider = Struct.new(
    :client_secret,
    :authorize_url,
    :access_token_url,
    keyword_init: true
  )

  class App < Sinatra::Base
    attr_reader :provider

    def initialize(app = nil, provider: nil)
      super app
      @provider = provider
    end

    configure :development do
      register Sinatra::Reloader
    end

    enable :sessions

    get '/oauth/authorize' do
      session[:original_redirect_uri] = params['redirect_uri']
      redirect to("#{provider.authorize_url}?#{authorize_params(request, params)}")
    end

    get '/oauth/code' do
      redirect to(session[:original_redirect_uri] + "?code=#{params[:code]}")
    end

    post '/oauth/access_token' do
      exchange_code_for_access_token(params)
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
