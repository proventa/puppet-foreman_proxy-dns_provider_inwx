require 'smart_proxy_dns_inwx/dns_inwx_version'
require 'smart_proxy_dns_inwx/dns_inwx_configuration'

module Proxy::Dns::Inwx
  class Plugin < ::Proxy::Provider
    plugin :dns_inwx, ::Proxy::Dns::Inwx::VERSION

    requires :dns, '>= 1.15'

    default_settings :inwx_user => nil, :inwx_pass => nil

    load_classes ::Proxy::Dns::Inwx::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::Dns::Inwx::PluginConfiguration
  end
end
