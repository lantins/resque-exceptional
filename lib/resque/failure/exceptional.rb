module Resque
  module Failure
    # A Resque failure backend that sends exception data to getexceptional.com
    class Exceptional < Base
      Version = '0.2.1' # Failure backend version number.

      # Raised if the api_key is not set.
      class APIKeyError < StandardError
      end

      class << self
        attr_accessor :api_key # your getexceptional api key.
        attr_accessor :use_ssl # enable/disable SSL.
        attr_accessor :deliver # whether or not to submit exceptions to Exceptional
        # HTTP proxy option
        attr_accessor :proxy_host, :proxy_port, :proxy_user, :proxy_pass
        # HTTP client option
        attr_accessor :http_open_timeout, :http_read_timeout
      end

      # Configures the failure backend. At a minimum you will need to set
      # an api_key.
      #
      # @example Setting your API Key and enabling SSL:
      #   Resque::Failure::Exceptional.configure do |config|
      #     config.api_key = '505f2518c41866bb0be7ba434bb2b079'
      #     config.use_ssl = true
      #   end
      def self.configure
        yield self
      end

      # Sends the exception data to the exceptional api.
      #
      # When a job fails, a new instance is created and #save is called.
      def save
        return unless deliver?
        return unless response = http_post_request

        if response.code == '200'
          log "success - api accepted the exception data."
        else
          body = response.body if response.respond_to? :body
          log "fail - expected: 200 OK, received: #{response.code} #{response.message}"
        end
      end

      # Sends a HTTP Post to the exceptional api.
      #
      # @return [Net::HTTPResponse] http response data.
      # @return [nil] if something went wrong.
      def http_post_request
        begin
          return http_client.post(http_path_query, compressed_request, http_headers)
        rescue APIKeyError
          log 'error - you must set your api_key.'
        rescue TimeoutError
          log 'fail - timeout while contacting the api server.'
        rescue Exception => e
          log "fail - exception raised during http post. (#{e.class.name}: #{e.message})"
        end
        nil
      end

      # HTTP headers to send.
      #
      # @return [Hash] http headers.
      def http_headers
        {
          'Content-Type' => 'application/json',
          'Accept'       => 'application/json',
          'User-Agent'   => "resque-exceptional/#{Version}"
        }
      end

      # Returns the compressed request data.
      def compressed_request
        Zlib::Deflate.deflate(MultiJson.dump(api_request), Zlib::BEST_SPEED)
      end

      # Path & query options used by the HTTP Post.
      #
      # @raise [APIKeyError] if the api_key is not set.
      # @return [String] http path & query options.
      def http_path_query
        raise APIKeyError, 'api key must be set.' unless self.class.api_key
        hash_param = uniqueness_hash.nil? ? nil : "&hash=#{uniqueness_hash}"
        "/api/errors?api_key=#{self.class.api_key}&protocol_version=5#{hash_param}"
      end

      # Calculates a uniqueness md5sum of the exception backtrace if available.
      #
      # nb. this isn't documented in the public api... not sure if we should
      # use it or not...
      #
      # @return [String] md5sum of the backtrace.
      # @return [nil] if we don't have a backtrace available.
      def uniqueness_hash
        return nil if (exception.backtrace.nil? || exception.backtrace.empty?)
        Digest::MD5.hexdigest(exception.backtrace.join)
      end

      # Configures a HTTP client.
      #
      # @return [Net::HTTP] http client.
      def http_client
        # pass any proxy settings.
        proxy = Net::HTTP::Proxy(self.class.proxy_host, self.class.proxy_port,
                                 self.class.proxy_user, self.class.proxy_pass)
        http = proxy.new('api.exceptional.io', http_port)

        # set http client options.
        http.read_timeout = self.class.http_read_timeout || 5
        http.open_timeout = self.class.http_open_timeout || 2
        http.use_ssl = use_ssl?

        http
      end

      # Helper method to return the correct HTTP port number, depending on
      # if were using SSL or not.
      #
      # @return [Fixnum] HTTP port number.
      def http_port
        use_ssl? ? 443 : 80
      end

      # Helper method to check if were using SSL or not.
      #
      # @return [Boolean] true if ssl is enabled.
      def use_ssl?
        self.class.use_ssl || false
      end

      # Helper method to check if errors should be submitted to exceptional API.
      #
      # @return [Boolean] true if deliver is enabled.
      def deliver?
        self.class.deliver.nil? || self.class.deliver
      end

      # Adds a prefix to log messages.
      #
      # @param [String] msg your log message.
      def log(msg)
        super("resque-exception - #{msg}")
      end

      # API request data structure.
      #
      # @return [Hash] data structure expected by the api.
      def api_request
        {
          'request' => {
            'parameters' => {
              'queue' => queue.to_s,
              'job_class' => payload['class'].to_s,
              'job_args' => payload['args'],
              'worker' => worker.to_s
            }
          },
          'application_environment' => {
            'env' => ENV.to_hash,
            'application_root_directory' => ENV['PWD']
          },
          'exception' => {
            'occurred_at' => Time.now.iso8601,
            'message' => "#{exception.class.name}: #{exception.message}",
            'backtrace' => Array(exception.backtrace),
            'exception_class' => exception.class.name
          },
          'rescue_block' => {
            'name' => 'Resque Failure'
          },
          'client' => {
            'name' => 'resque-exceptional',
            'version' => Resque::Failure::Exceptional::Version,
            'protocol_version' => 5
          }
        }
      end

    end
  end
end
