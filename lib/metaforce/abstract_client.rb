module Metaforce
  class AbstractClient

    NAMESPACES = {
      "xmlns:metadata" => "http://soap.sforce.com/2006/04/metadata",
      "xmlns:ins0" => "http://soap.sforce.com/2006/04/metadata",
      "xmlns:partner"  => "urn:partner.soap.sforce.com"
    }


    class << self
      # Internal
      def endpoint(key)
        define_method :endpoint do; @options[key] end
      end

      # Internal
      def wsdl(wsdl)
        define_method :wsdl do; wsdl end
      end
    end

    # Public: Initialize a new client.
    #
    # options - A hash of options, which should have a :session_id key
    def initialize(options={})
      raise 'Please specify a hash of options' unless options.is_a?(Hash)
      @options = options
    end

    private

    # Internal: The Savon client to send SOAP requests with.
    def client
      @client ||=
        begin
          options = {
            endpoint: endpoint,
            ssl_verify_mode: :none,
            wsdl: wsdl,
            namespaces: NAMESPACES
          }

          if Metaforce.log?
            options.merge!(log: true)
          end

          if Metaforce.configuration.pretty_print
            options.merge!(pretty_print_xml: true)
          end

          if proxy = Metaforce.configuration.proxy
            options.merge!(proxy: proxy)
          end

          Savon.client(options).tap do |c|
            c.globals.soap_header soap_headers
          end
        end
      @client
    end

    # Internal: Performs a SOAP request. If the session is invalid, it will
    # attempt to reauthenticate by called the reauthentication handler if
    # present.
    def request(*args, &block)
      authenticate! unless session_id
      retries = authentication_retries
      begin
        perform_request(*args, &block)
      rescue Savon::SOAPFault => e
        if e.message =~ /INVALID_SESSION_ID/ && authentication_handler && retries > 0
          authenticate!
          retries -= 1
          retry
        end
        raise
      end
    end

    def perform_request(*args, &block)
      opts = args.extract_options!

      response = client.call(args[0], opts, &block)
      Hashie::Mash.new(response.body)[:"#{args[0]}_response"].result.tap do |resp|
        Metaforce.debug(resp)
      end
    end

    # Internal Calls the authentication handler, which should set @options to a new
    # hash.
    def authenticate!
      options = authentication_handler.call(self, @options)
      @options.merge!(options)
      client.globals[:soap_header] = soap_headers
    end

    # A proc object that gets called when the client needs to reauthenticate.
    def authentication_handler
      Metaforce.configuration.authentication_handler
    end

    def authentication_retries
      3
    end

    # Internal: Soap headers to set for authenticate.
    def soap_headers
      { 'ins0:SessionHeader' => { 'ins0:sessionId' => session_id } }
    end

    # Internal: The session id, which can be obtained by calling
    # Metaforce.login or through OAuth.
    def session_id
      @options[:session_id]
    end
  end
end
