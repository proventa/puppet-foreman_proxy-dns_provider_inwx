#Integration of Inwx as DNS provider in Puppet Forman Smart Proxy module

Integrates Internetworx as DNS provider to create and delete nameserver records via API.

## Compatibility

This module only supports the Proventa fork of Smart Proxy 1.6 or higher as of version 2.0
https://github.com/proventa/puppet-foreman_proxy

## Installation

1. Clone repository into `/usr/share/foreman-proxy/modules/dns/providers`
2. Set ownership of directory `inwx/` to foreman-proxy: `chown foreman-proxy:foreman-proxy inwx/`
3. Configure puppet variables `dns_provider`, `dns_user`, `dns_password` and `dns_server` of module foreman_proxy
  * dns_provider = inwx
  * dns_user = (your inwx-username)
  * dns_password = (your inwx-password)
  * dns_server = ns.inwx.de
4. Enable Smart Proxy module dns
