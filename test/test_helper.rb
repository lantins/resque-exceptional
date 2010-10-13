dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'
$TESTING = true

require 'test/unit'
require 'rubygems'
require 'simplecov'
require 'rr'

SimpleCov.start do
  add_filter "/test/"
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

# require our failure backend to test.
require 'resque-exceptional'

# fake worker.
class FakeWorker
  attr_reader :log_history

  def initialize
    @log_history = []
  end

  def log(msg)
    @log_history << msg
    p msg
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