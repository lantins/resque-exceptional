spec = Gem::Specification.new do |s|
  s.name              = 'resque-exceptional'
  s.version           = '0.2.2'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = 'A Resque failure backend for getexceptional.com'
  s.license           = 'MIT'
  s.homepage          = 'http://github.com/lantins/resque-exceptional'
  s.authors           = ['Luke Antins']
  s.email             = 'luke@lividpenguin.com'
  s.has_rdoc          = false

  s.files             = %w(LICENSE Rakefile README.md HISTORY.md)
  s.files            += Dir.glob('{test/*,lib/**/*}')
  s.require_paths     = ['lib']

  s.add_runtime_dependency('resque', '>= 1.8')
  s.add_runtime_dependency('multi_json', '~> 1.0')
  s.add_development_dependency('rake')
  s.add_development_dependency('minitest', '~> 5.2')
  s.add_development_dependency('rr', '~> 1.1')
  s.add_development_dependency('webmock', '~> 1.8')
  s.add_development_dependency('yard', '~> 0.8')
  s.add_development_dependency('simplecov', '~> 0.7.1')

  s.description       = <<-EOL
  resque-exceptional provides a Resque failure backend that sends exceptions
  raised by jobs to getexceptional.com.
  EOL
end
