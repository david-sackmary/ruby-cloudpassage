require 'oauth2'
require 'rest-client'
require 'json'

module Cloudpassage
  RestClient.proxy = ENV['HTTPS_PROXY'] if ENV['HTTPS_PROXY'].to_s.length > 0

  def self.token(client_id, client_secret)
    client = OAuth2::Client.new(client_id, client_secret,
                                :connection_opts => { :proxy => ENV['HTTPS_PROXY'] },
                                :site => 'https://api.cloudpassage.com',
                                :token_url => '/oauth/access_token')
    client.client_credentials.get_token.token
  end
end