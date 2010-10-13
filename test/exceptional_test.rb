require File.dirname(__FILE__) + '/test_helper'

# Tests the failure backend works with resque, does not contact the api.
class ExceptionalTest < Test::Unit::TestCase
  def setup
    @exception = TestApp.grab_exception
    @worker = FakeWorker.new
    @queue = 'test_queue'
    @payload = { 'class' => 'TestJob', 'args' => ['foo', 'bar'] }
    @failure = Resque::Failure::Exceptional.new(@exception, @worker, @queue, @payload)
  end

  # test we can build a hash to send to the api.
  def test_can_build_api_request_data_hash
    data = @failure.api_request
    assert_kind_of Hash, data, 'should build a hash'
  end

  # include the minimum entries required by the api.
  def test_api_request_includes_minimum_api_entries
    data = @failure.api_request

    assert_kind_of Hash,   data['application_environment']
    assert_kind_of Hash,   data['application_environment']['env']
    assert_kind_of String, data['application_environment']['application_root_directory']

    assert_kind_of Hash, data['exception']
    # test occurred_at that starts like: 2010-10-13T01:56:49
    assert_match /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, data['exception']['occurred_at']
    assert_kind_of String, data['exception']['message']
    assert_kind_of Array, data['exception']['backtrace']
    assert_equal 'TestApp::Error', data['exception']['exception_class']
  end

  # include the resque information, we sneak it in as request data so we can
  # view it via the web interface.
  def test_api_request_includes_resque_info
    data = @failure.api_request

    assert_kind_of Hash,   data['request']
    assert_kind_of Hash,   data['request']['parameters']
    assert_kind_of String, data['request']['parameters']['queue']
    assert_kind_of String, data['request']['parameters']['job_class']
    assert_kind_of Array,  data['request']['parameters']['job_args']
    assert_kind_of String, data['request']['parameters']['worker']
  end

  # make it more obvious in the web interface this was a resque failure.
  def test_api_request_includes_resque_block
    data = @failure.api_request

    assert_kind_of Hash, data['rescue_block']
    assert_equal 'Resque Failure', data['rescue_block']['name']
  end

  # let them know who we are.
  def test_api_request_includes_client_info
    data = @failure.api_request

    assert_equal 'resque-exceptional', data['client']['name'], 'should use the gem name'
    assert_match /^\d+\.\d+\.\d+$/, data['client']['version'], 'should have a version number'
    assert_kind_of Fixnum, data['client']['protocol_version']
  end

  # we need the ability to configure the failure backend before its created.
  # config settings should be class variables.
  def test_configure
    Resque::Failure::Exceptional.configure do |config|
      config.api_key = 'my api key.'
      # everything below are http client options.
      config.proxy_host = 'host.name.com'
      config.proxy_port = 8080
      config.proxy_user = 'foo'
      config.proxy_pass = 'bar'
      config.use_ssl = true
      config.http_open_timeout = 5
      config.http_read_timeout = 10
    end

    # reset everything to nil...
    Resque::Failure::Exceptional.configure do |config|
      options = %w{api_key proxy_host proxy_port proxy_user proxy_pass use_ssl
                   http_open_timeout http_read_timeout}
      options.each { |opt| config.send("#{opt}=", nil) }
    end
  end

  # failure backends need to define a save method.
  def test_save_defined
    assert_equal true, @failure.respond_to?(:save)
  end

  # we need a Net::HTTP client setup to send the data.
  def test_http_client
    
  end

  # perform a test with the real api.
  def test_live_fire
    omit 'comment this line, set your api key, test with real api!'
    Resque::Failure::Exceptional.configure { |c| c.api_key = 'your-api-key' }
    @failure.save
    assert_match /^(resque-exception).*(success).*$/, @worker.log_history.first
    # reset.
    Resque::Failure::Exceptional.configure { |c| c.api_key = nil }
  end

  # we should fail if the api_key is not set.
  def test_fail_if_api_key_nil
    # should already be nil, but lets just be sure...
    Resque::Failure::Exceptional.configure { |c| c.api_key = nil }
    @failure.save
    assert_match /^(resque-exception).*(error).*(api_key).*$/, @worker.log_history.first
  end

  # should handle exceptions raised during the HTTP Post.
  # should return and not raise anything if we were successful.
end