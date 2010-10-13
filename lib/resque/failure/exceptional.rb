module Resque
  module Failure

    # A resque failure backend that sends exception data to getexceptional.com
    class Exceptional < Base
      # Raised if the api_key is not set.
      class APIKeyError < StandardError
      end

      # Our version number =)
      Version = '0.0.1'

      class << self
        # API Settings.
        attr_accessor :api_key
        # HTTP Proxy Options.
        attr_accessor :proxy_host, :proxy_port, :proxy_user, :proxy_pass
        # HTTP Client Options.
        attr_accessor :use_ssl, :http_open_timeout, :http_read_timeout
      end

      # Configures the failure backend. At a minimum you will need to set
      # an api_key.
      def self.configure
        yield self
      end

      # Sends the exception data to the exceptional api.
      #
      # When a job fails, a new instance is created and #save is called.
      def save
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
        { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
      end

      # Returns the compressed request data.
      def compressed_request
        Zlib::Deflate.deflate(api_request.to_json, Zlib::BEST_SPEED)
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
        http = proxy.new('api.getexceptional.com', http_port)

        # set http client options.
        http.read_timeout = self.class.http_read_timeout || 5
        http.open_timeout = self.class.http_open_timeout || 2
        http.use_ssl = use_ssl?

        http
      end

      # Helper method to return the correct HTTP port number.
      def http_port
        use_ssl? ? 443 : 80
      end

      # Helper method to check if were using SSL or not.
      def use_ssl?
        self.class.use_ssl || false
      end

      # Adds a prefix to log messages.
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