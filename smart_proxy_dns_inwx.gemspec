require File.expand_path('../lib/smart_proxy_dns_inwx/dns_inwx_version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'smart_proxy_dns_inwx'
  s.version     = Proxy::Dns::Inwx::VERSION
  s.date        = Date.today.to_s
  s.license     = 'GPL-3.0'
  s.authors     = ['Clemens Bergmann']
  s.email       = ['c.bergmann@proventa.de']
  s.homepage    = 'https://github.com/proventa/smart_proxy_dns_inwx'

  s.summary     = "INWX DNS provider plugin for Foreman's smart proxy"
  s.description = "INWX DNS provider plugin for Foreman's smart proxy"

  s.files       = Dir['{config,lib,bundler.d}/**/*'] + ['README.md', 'LICENSE']

  s.add_dependency 'inwx-rb'
end
