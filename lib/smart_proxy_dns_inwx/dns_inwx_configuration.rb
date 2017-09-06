module ::Proxy::Dns::Inwx
  class PluginConfiguration
    def load_classes
      require 'smart_proxy_dns_inwx/dns_inwx_main'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      container_instance.dependency :dns_provider, (lambda do
        ::Proxy::Dns::Inwx::Record.new(
            settings[:inwx_user],
            settings[:inwx_pass])
      end)
    end
  end
end
