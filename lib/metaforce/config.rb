module Metaforce

  class Configuration

    NAMESPACES = {
      "xmlns:metadata" => "http://soap.sforce.com/2006/04/metadata",
      "xmlns:ins0" => "http://soap.sforce.com/2006/04/metadata",
      "xmlns:partner"  => "urn:partner.soap.sforce.com"
    }

    attr_accessor :pretty_print
    attr_accessor :proxy
    # The Salesforce API version to use. Defaults to 23.0
    attr_accessor :api_version
    # The username to use during login.
    attr_accessor :username
    # The password to use during login.
    attr_accessor :password
    # The security token to use during login.
    attr_accessor :security_token
    # Set this to true if you're authenticating with a Sandbox instance.
    # Defaults to false.
    attr_accessor :host
    # A block that gets called when the session becomes invalid and the
    # client needs to reauthenticate. Passes in the client and the client
    # options. The block should set the options to a hash containing a valid
    # session_id and service urls.
    attr_accessor :authentication_handler
    # Enables or disables threading when polling for job status. If disabled,
    # calling .perform on a job will block until completion and all callbacks
    # have run. (default: true).
    attr_accessor :threading

    def initialize
      @threading = false
    end

    def api_version
      @api_version ||= '26.0'
    end

    def host
      @host ||= 'login.salesforce.com'
    end

    def pretty_print
      @pretty_print || false
    end

    def authentication_handler
      @authentication_handler ||= lambda { |client, options|
        Metaforce.login(options)
      }
    end

    def log=(log)
      HTTPI.log = log
    end

    def partner_wsdl
      File.join(wsdl, 'partner.xml')
    end

    def metadata_wsdl
      File.join(wsdl, 'metadata.xml')
    end

    def endpoint
      "https://#{host}/services/Soap/u/#{api_version}"
    end

    def wsdl
      File.expand_path("../../../wsdl/#{api_version}", __FILE__)
    end

    def logger
      @logger ||= ::Logger.new STDOUT
    end

    def soap_options(opts = {})
      {
        endpoint: endpoint,
        ssl_verify_mode: :none,
        wsdl: wsdl,
        namespaces: NAMESPACES
      }.tap do |options|
        options.merge!(log: true) if Metaforce.log?
        options.merge!(pretty_print_xml: true) if Metaforce.configuration.pretty_print

        if proxy = Metaforce.configuration.proxy
          options.merge!(proxy: proxy)
        end
      end

    end
  end
end
