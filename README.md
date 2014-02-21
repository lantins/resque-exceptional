resque-exceptional
==================

resque-exceptional provides a [Resque][re] failure backend that sends exceptions
raised by jobs to [getexceptional.com][ge]

[![Build Status](https://secure.travis-ci.org/lantins/resque-exceptional.png?branch=master)](http://travis-ci.org/lantins/resque-exceptional)

Install & Quick Start
---------------------

Before you jump into code, you'll need a getexceptional.com account.

To install:

    $ gem install resque-exceptional

### Example: Single Failure Backend

Using only the exceptional failure backend:

    require 'resque'
    require 'resque-exceptional'

    Resque::Failure::Exceptional.configure do |config|
      config.api_key = '505f2518c41866bb0be7ba434bb2b079'
      config.use_ssl = false
    end

    Resque::Failure.backend = Resque::Failure::Exceptional

### Example: Multiple Failure Backends

Using both the redis and exceptional failure backends:

    require 'resque'
    require 'resque-exceptional'

    require 'resque/failure/multiple'
    require 'resque/failure/redis'

    Resque::Failure::Exceptional.configure do |config|
      config.api_key = '505f2518c41866bb0be7ba434bb2b079'
    end

    Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Exceptional]
    Resque::Failure.backend = Resque::Failure::Multiple

Configuration Options
---------------------

**Required**

  * `api_key` - your getexceptional.com api key.

**General Options** *(optional)*

  * `deliver` - set `false` to disable delivery of errors to exceptional API, handy for testing (default: `true`)

**HTTP Proxy Options** *(optional)*

  * `proxy_host` - proxy server ip / hostname.
  * `proxy_port` - proxy server port.
  * `proxy_user` - proxy server username.
  * `proxy_pass` - proxy server password.

**HTTP Client Options** *(optional)*

  * `use_ssl` - set `true` if your plan supports ssl. (default: `false`)
  * `http_open_timeout` - timeout in seconds to establish the connection. (default: `2`)
  * `http_read_timeout` - timeout in seconds to wait for a reply. (default: `5`)

Note on Patches/Pull Requests
-----------------------------

  * Fork the project.
  * Make your feature addition or bug fix.
  * Add tests for it. This is important so I don't break it in a future
    version unintentionally.
  * Commit, do not mess with the version. (if you want to have your own
    version, that is fine but bump version in a commit by itself I can ignore
    when I pull)
  * Send me a pull request. Bonus points for topic branches.

Author
------

Luke Antins :: [http://lividpenguin.com][lp] :: @lantins

[re]: http://github.com/defunkt/resque
[lp]: http://lividpenguin.com
[ge]: http://getexceptional.com