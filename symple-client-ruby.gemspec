Gem::Specification.new do |s|
  s.name        = 'symple-client-ruby'
  s.version     = '2.0.0'
  s.summary     = 'Ruby client for the Symple realtime messaging server'
  s.description = 'Emit Socket.IO messages and manage sessions via Redis from Ruby/Rails, compatible with the Symple server and @socket.io/redis-adapter.'
  s.authors     = ['Kam Low']
  s.email       = 'auscaster@gmail.com'
  s.homepage    = 'https://github.com/sourcey/symple-client-ruby'
  s.license     = 'MIT'

  s.files       = Dir['lib/**/*.rb'] + ['symple.rb', 'README.md']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'redis', '>= 4.0'
  s.add_dependency 'msgpack', '>= 1.0'
end
