module Metaforce
  class Login
    def initialize(username, password, security_token=nil)
      @username, @password, @security_token = username, password, security_token
    end

    # Public: Perform the login request.
    #
    # Returns a hash with the session id and server urls.
    def login
      message = {
        :username => username,
        :password => password
      }

      response = client.call(:login, message: message)
      response.body[:login_response][:result]
    end

  private

    # Internal: Savon client.
  def client
    options = {
      wsdl: Metaforce.configuration.partner_wsdl,
      endpoint: Metaforce.configuration.endpoint,
      ssl_verify_mode: :none
    }

    if proxy = Metaforce.configuration.proxy
      options.merge!(proxy: proxy)
    end

    @client ||= Savon.client(options)
  end

    # Internal: Usernamed passed in from options.
    def username
      @username
    end

    # Internal: Password + Security Token combined.
    def password
      [@password, @security_token].join('')
    end
  end
end
