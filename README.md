resque-exceptional
==================

resque-exceptional provides a [Resque][re] failure backend that sends exceptions
raised by jobs to [getexceptional.com][ge]

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

**HTTP Proxy Options** *(optional)*

  * `proxy_host` - proxy server ip / hostname.
  * `proxy_port` - proxy server port.
  * `proxy_user` - proxy server username.
  * `proxy_pass` - proxy server password.

**HTTP Client Options** *(optional)*

  * `use_ssl` - set `true` if your plan supports ssl. (default: `false`)
  * `http_open_timeout` - timeout in seconds to establish the connection. (default: `2`)
  * `http_read_timeout` - timeout in seconds to wait for a reply. (default: `5`)

Screenshots
-----------

Below are some screenshots of the getexceptional.com web interface, showing
Resque exceptions.

**App Overview**
![Get Exceptional - Overview](http://img.skitch.com/20101013-k7hgurmaqew6sn8cik5gywbt2.png)

**Detailed Information**
![Get Exceptional - Details](http://img.skitch.com/20101013-ftjrjhh3fegcqr9mig9kttmwi4.png)

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