require 'resolv'
require 'resolv-replace'
require 'yaml'
require 'inwx/domrobot'

module Proxy::Dns::Inwx
  class Record < ::Proxy::Dns::Record
    include Proxy::Log
    include Proxy::Util

    attr_accessor :domrobot
    attr_accessor :object

    def initialize(inwx_user, inwx_pass, ttl = nil)
      addr = "api.domrobot.com"
      @object = "nameserver"
      @domrobot = INWX::Domrobot.new(addr)
      result = self.domrobot.login(inwx_user,inwx_pass)
      super(nil, ttl)
    end

    # create({ :fqdn => "node01.lab", :value => "192.168.100.2"}
    # create({ :fqdn => "node01.lab", :value => "3.100.168.192.in-addr.arpa",
    #          :type => "PTR"}
    def do_create(name, value, type)
      ip, id = dns_find(name)
      if ip
        raise(Proxy::Dns::Collision, "#{name} is already used") unless ip == value
      else
        domain, name = split_fqdn(name)
        method = "createRecord"
        params = {:domain => domain, :type => type, :content => value, :name => name }
        result = self.domrobot.call(self.object, method, params)
        msg = "add #{type} DNS entry #{name} => #{value} to domain #{domain}"
        report msg, result["msg"], false
      end
    end

    # remove({ :fqdn => "node01.lab", :value => "192.168.100.2"}
    # remove({ :fqdn => "node01.lab", :value => "3.100.168.192.in-addr.arpa"}
    def do_remove(name, value)
      ip, id = dns_find(name)
      raise Proxy::Dns::NotFound.new("Cannot find DNS entry for #{name}") unless id
      msg = "remove DNS entry #{name} => #{value}"
      method = "deleteRecord"
      params = { :id => id }
      result = self.domrobot.call(self.object, method, params)

      report msg, result["msg"], false
    end

    private
 
    def resolver
      @resolver ||= Resolv::DNS.new
    end
 
    def report msg, response, error_only=false
      if not response.include? "completed successfully"
        logger.error "Inwx failed:\n" + response.join("\n")
        msg  = "Failed to #{msg}"
        raise Proxy::Dns::Error.new(msg)
      else
        logger.info msg unless error_only
      end
    rescue Proxy::Dns::Error
      raise
    rescue
      logger.error "Inwx failed:\n #{response}"
      raise Proxy::Dns::Error.new("Unknown error while processing '#{msg}'")
    end

    def split_fqdn fqdn
      method = "list"
      params = { :pagelimit => 0 }
      result = self.domrobot.call(self.object, method, params)
      result["resData"]["domains"].each do |domain|
        domain=domain["domain"]
        if fqdn.end_with?(domain)
          return [domain,fqdn.chomp(".#{domain}")]
        end
      end
      raise Proxy::Dns::Error.new("Could not find domain for host #{fqdn}")
    end

    def dns_find fqdn
      domain, name = split_fqdn(fqdn)
      method = "info"
      params = { :domain => domain, :name => name }
      result = self.domrobot.call(self.object, method, params)
      return false if result["resData"]["record"].nil?

      return [ result["resData"]["record"][0]["content"], result["resData"]["record"][0]["id"] ]
    end
  end
end
