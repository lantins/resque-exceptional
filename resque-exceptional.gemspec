require 'lib/resque-exceptional'

spec = Gem::Specification.new do |s|
  s.name              = 'resque-exceptional'
  s.version           = Resque::Failure::Exceptional::Version
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = 'A Resque failure backend for getexceptional.com'
  s.homepage          = 'http://github.com/lantins/resque-exceptional'
  s.authors           = ['Luke Antins']
  s.email             = 'luke@lividpenguin.com'
  s.has_rdoc          = false

  s.files             = %w(LICENSE Rakefile README.md HISTORY.md)
  s.files            += Dir.glob('{test/*,lib/**/*}')
  s.require_paths     = ['lib']

  s.add_dependency('resque', '>= 1.8.0')
  s.add_development_dependency('test-unit')
  s.add_development_dependency('rr', '>= 1.0.0')
  s.add_development_dependency('yard')
  s.add_development_dependency('simplecov', '>= 0.3.0')

  s.description       = <<-EOL
  resque-exceptional provides a Resque failure backend that sends exceptions
  raised by jobs to getexceptional.com.
  EOL
end