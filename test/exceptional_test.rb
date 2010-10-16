require File.dirname(__FILE__) + '/test_helper'

# Tests the failure backend works with resque, does not contact the api.
class ExceptionalTest < Test::Unit::TestCase
  def setup
    @exception = TestApp.grab_exception
    @worker = FakeWorker.new
    @queue = 'test_queue'
    @payload = { 'class' => 'TestJob', 'args' => ['foo', 'bar'] }
    @failure = Resque::Failure::Exceptional.new(@exception, @worker, @queue, @payload)
    WebMock.disable_net_connect!
    WebMock.reset_webmock
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
    assert_kind_of Net::HTTP, @failure.http_client
  end

  # we should fail if the api_key is not set.
  def test_fail_if_api_key_nil
    # should already be nil, but lets just be sure...
    with_api_key nil do
      @failure.save
      assert_match /^(resque-exception).*(error).*(api_key).*$/, @worker.log_history.first
    end
  end

  # test we prefix our log messages.
  def test_log_adds_prefix
    @failure.log('test message')
    @failure.log('123 another msg bud!')
    assert_match /^resque-exception - .*/, @worker.log_history.first
    assert_match /^resque-exception - .*/, @worker.log_history.last
  end

  # test our `#use_ssl?` and `#http_port` helper methods.
  def test_helper_methods
    # check defaults
    assert_equal false, @failure.use_ssl?, 'use_ssl? should default to false.'
    assert_equal 80, @failure.http_port, 'http_port should default to 80.'

    # enable ssl.
    Resque::Failure::Exceptional.configure { |c| c.use_ssl = true }
    assert_equal true, @failure.use_ssl?, 'use_ssl? should now be true'
    assert_equal 443, @failure.http_port, 'http_port should now be 443.'

    # put the config back.
    Resque::Failure::Exceptional.configure { |c| c.use_ssl = false }
  end

  # returns nil if the backtrace is empty.
  def test_uniqueness_hash_returns_nil_when_empty_backtrace
    mock(@failure.exception).backtrace.times(any_times) { Array.new }
    assert_equal nil, @failure.uniqueness_hash
  end

  # returns nil if the backtrace is empty.
  def test_uniqueness_hash_returns_nil_when_nil_backtrace
    mock(@failure.exception).backtrace.times(any_times) { nil }
    assert_equal nil, @failure.uniqueness_hash
  end

  # uniqueness_hash builds a md5sum.
  def test_uniqueness_hash_returns_a_md5_of_the_backtrace
    # fake backtrace.
    fake_backtrace = ['fake', 'backtrace', 'that_wont_change']
    mock(@failure.exception).backtrace.times(any_times) { fake_backtrace }

    assert_equal '27810b263f0e11eef2f1d29be75d2f39', @failure.uniqueness_hash
  end

  # return the HTTP path and query string with uniqueness hash.
  def test_http_path_query
    # fake backtrace.
    fake_backtrace = ['fake', 'backtrace', 'that_wont_change']
    mock(@failure.exception).backtrace.times(any_times) { fake_backtrace }

    with_api_key '27810b263f0e11eef2f1d29be75d2f39' do
      path, query = *@failure.http_path_query.split('?', 2)
      assert_match /^api_key=27810b263f0e11eef2f1d29be75d2f39/, query, 'query should have api_key.'
      assert_match /protocol_version=\d{1}/, query, 'query should have protocol_version.'
      assert_match /hash=27810b263f0e11eef2f1d29be75d2f39$/, query, 'query should have a uniqueness hash.'
    end
  end

  # build a path & query without a uniqueness hash.
  def test_http_path_query_without_uniqueness_hash
    # fake empty backtrace.
    mock(@failure.exception).backtrace.times(any_times) { Array.new }

    with_api_key '27810b263f0e11eef2f1d29be75d2f39' do
      path, query = *@failure.http_path_query.split('?', 2)
      assert_match /^api_key=27810b263f0e11eef2f1d29be75d2f39/, query, 'query should have api_key.'
      assert_match /protocol_version=\d{1}$/, query, 'query should have protocol_version.'
    end
  end

  # raise exception if api key is not set.
  def test_http_path_query_without_api_key_raises_exception
    assert_raise Resque::Failure::Exceptional::APIKeyError, 'should raise APIKeyError if api key is not set' do
      @failure.http_path_query
    end
  end

  # should return http response if successful.
  def test_http_post_request
    with_api_key '27810b263f0e11eef2f1d29be75d2f39' do
      stub_request(:post, /.*api.getexceptional.com.*/)

      response = @failure.http_post_request
      assert_requested(:post, /.*api.getexceptional.com.*/)
      assert_equal '200', response.code, 'should be a successful http request'
    end
  end

  # should handle exceptions raised during the HTTP Post.
  def test_http_post_request_handles_exceptions_and_returns_nil
    response = @failure.http_post_request
    assert_equal nil, @failure.http_post_request, 'should be nil, APIKeyError should have been caught.'

    with_api_key '27810b263f0e11eef2f1d29be75d2f39' do
      WebMock.reset_webmock
      stub_request(:post, /.*api.getexceptional.com.*/).to_raise(StandardError)
      assert_equal nil, @failure.http_post_request, 'should be nil, StandardError should have been caught.'
      assert_requested(:post, /.*api.getexceptional.com.*/)
    end
  end

  # make sure we catch timeout errors.
  def test_http_post_request_timeout
    with_api_key '27810b263f0e11eef2f1d29be75d2f39' do
      stub_request(:post, /.*api.getexceptional.com.*/).to_timeout
      assert_equal nil, @failure.http_post_request, 'should be nil, TimeoutError should have been caught.'
      assert_requested(:post, /.*api.getexceptional.com.*/)
    end
  end

  # perform a test with the real api.
  def test_live_fire_with_real_api!
    unless ENV['EXCEPTIONAL_API_KEY']
      omit 'Test with the REAL API. Example: `EXCEPTIONAL_API_KEY=27810b263f0e11eef2f1d29be75d2f39 rake test`'
    end

    with_api_key ENV['EXCEPTIONAL_API_KEY'] do
      WebMock.allow_net_connect!
      @failure.save
      assert_match /^(resque-exception).*(success).*$/, @worker.log_history.first
    end
  end

end