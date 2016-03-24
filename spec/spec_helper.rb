require 'bundler'
Bundler.require :default, :development
require 'pp'
require 'pry'
require 'rspec/mocks'
require "savon/mock/spec_helper"
require 'vcr'

Dir['./spec/support/**/*.rb'].sort.each {|f| require f}

VCR.configure do |c|
  c.hook_into :webmock # fakeweb fails with savon
  c.ignore_hosts 'www.some-url.com'
  c.configure_rspec_metadata!
  c.ignore_localhost                        = true
  c.cassette_library_dir                    = 'spec/support/vcr_cassettes'
  c.allow_http_connections_when_no_cassette = true
  c.default_cassette_options                = { allow_playback_repeats: true, match_requests_on: [:method, :uri, :headers] }
  # c.debug_logger                            = File.open(Rails.root.join('log/vcr.log'), 'w')
end
RSpec.configure do |config|
  config.filter_run_including :focus => true
  config.mock_with :rspec
  config.before(:example) {
    Metaforce.configuration.threading = false
    # savon.mock!
  }
  # config.after(:example)   { savon.unmock! }
end

RSpec::Matchers.define :set_default do |option|
  chain :to do |value|
    @value = value
  end

  match do |configuration|
    @actual = configuration.send(option.to_sym)
    @actual.should eq @value
  end

  failure_message_for_should do |configuration|
    "Expected #{option} to be set to #{@value.inspect}, got #{@actual.inspect}"
  end
end


Savon::Spec::Fixture.path = File.join(File.dirname(__FILE__), 'fixtures/requests')
