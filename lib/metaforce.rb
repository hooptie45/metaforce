require 'savon'
require 'pry'
require 'hashie'
require 'active_support'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'

require 'metaforce/version'

module Metaforce
  autoload :Manifest, 'metaforce/manifest'
  autoload :Login,    'metaforce/login'
  autoload :Client,   'metaforce/client'

  class << self

    attr_writer :log, :debug

    # Public: Initializes instances of the metadata and services api clients
    # and provides helper methods for deploying and retrieving code.
    def new(*args)
      Client.new(*args)
    end

    # Performs a login and retrurns the session
    def login(options={})
      options = options.with_indifferent_access
      username       = options.fetch(:username, ENV['SALESFORCE_USERNAME'])
      password       = options.fetch(:password, ENV['SALESFORCE_PASSWORD'])
      security_token = options.fetch(:security_token, ENV['SALESFORCE_SECURITY_TOKEN'])
      Login.new(username, password, security_token).login
    end

    # Returns the current Configuration
    #
    #    Metaforce.configuration.username = "username"
    #    Metaforce.configuration.password = "password"
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the Configuration
    #
    #    Metaforce.configure do |config|
    #      config.username = "username"
    #      config.password = "password"
    #    end
    def configure
      yield configuration
    end

    def debug?
      @debug ||= false
    end

    def log?
      @log ||= false
    end

    def log(message)
      return unless Metaforce.log?
      Metaforce.configuration.logger.send :debug, message
    end

    def debug(message)
      return unless Metaforce.debug?
      return if message.nil?

      StringIO.new(message.pretty_inspect).each do |line|
        Metaforce.configuration.logger.send :debug, line.chomp
      end
    end

  end
end

require 'metaforce/config'
require 'metaforce/job'
require 'metaforce/abstract_client'
require 'metaforce/services/client'
require 'metaforce/metadata/client'

# Metaforce.debug = true
# Metaforce.log = true
# Metaforce.configuration.pretty_print = true
# Metaforce.configuration.threading = true
