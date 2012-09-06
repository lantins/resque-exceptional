spec = Gem::Specification.new do |s|
  s.name              = 'resque-exceptional'
  s.version           = '0.2.0'
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
  s.add_dependency('multi_json')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
  s.add_development_dependency('rr')
  s.add_development_dependency('webmock')
  s.add_development_dependency('yard')
  s.add_development_dependency('simplecov')
  # for 1.8 use a better timer please.
  s.add_development_dependency('SystemTimer') if Gem.ruby_version < Gem::Version.new('1.9')

  s.description       = <<-EOL
  resque-exceptional provides a Resque failure backend that sends exceptions
  raised by jobs to getexceptional.com.
  EOL
end