resque-exceptional
==================

resque-exceptional provides a Resque failure backend that sends exceptions
raised by jobs to http://getexceptional.com

Install & Quick Start
---------------------

Before you jump into code, you'll need a http://getexceptional.com account.

To install:

    $ gem install resque-exceptional

### Example: Single Failure Backend

Using only the exceptional failure backend:

    require 'resque'
    require 'resque-exceptional'

    Resque::Failure::Exceptional.configure do |config|
      config.api_key = 'fc49503482dec7bf13eda286c99ab2bf'
      config.ssl = false
    end

    Resque::Failure.backend = Resque::Failure::Exceptional

### Example: Multiple Failure Backends

Using both the redis and exceptional failure backends:

    require 'resque'
    require 'resque-exceptional'

    require 'resque/failure/multiple'
    require 'resque/failure/redis'

    Resque::Failure::Exceptional.configure do |config|
      config.api_key = 'fc49503482dec7bf13eda286c99ab2bf'
    end

    Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Exceptional]
    Resque::Failure.backend = Resque::Failure::Multiple

Configuration Options
---------------------

 * `api_key` - getexceptional.com your api key.
 * `ssl` - if your plan supports ssl, set `true`

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

Luke Antins :: http://lividpenguin.com :: @lantins