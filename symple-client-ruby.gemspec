Gem::Specification.new do |s|
  s.name        = 'symple-client-ruby'
  s.version     = '4.0.0'
  s.summary     = 'Ruby client for the Symple v4 realtime messaging server'
  s.description = 'Emit Symple protocol messages and manage sessions via Redis from Ruby/Rails.'
  s.authors     = ['Kam Low']
  s.email       = 'auscaster@gmail.com'
  s.homepage    = 'https://auscaster.com/symple'
  s.license     = 'MIT'

  s.files       = Dir['lib/**/*.rb'] + ['symple.rb', 'README.md']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'redis', '>= 4.0'
end
