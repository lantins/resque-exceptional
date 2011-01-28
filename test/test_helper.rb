require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'
$TESTING = true

gem 'test-unit'
require 'test/unit'
require 'rubygems'
require 'rr'
require 'webmock'
require 'webmock/test_unit'

# require our failure backend to test.
require 'resque-exceptional'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
  include WebMock::API

  # periodicly set the api key.
  def with_api_key(key, &block)
    Resque::Failure::Exceptional.api_key = key
    yield
    Resque::Failure::Exceptional.api_key = nil
  end
end

# fake worker.
class FakeWorker
  attr_reader :log_history

  def initialize
    @log_history = []
  end

  def log(msg)
    @log_history << msg
    p msg if ENV['VERBOSE']
  end

  def to_s
    'mr. fake resque worker.'
  end
end

# test exceptions.
module TestApp
  class Error < StandardError
  end

  def self.method_bar
    raise Error, 'example exception message. bar.'
  end

  def self.method_foo
    method_bar
  end

  def self.grab_exception
    begin
      method_foo
    rescue => e
      return e
    end
  end

end
