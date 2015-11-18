require 'resolv'
require 'resolv-replace'
require_relative 'inwx/Domrobot'
require 'yaml'

module Proxy::Dns
  class Inwx < Record
    include Proxy::Log
    include Proxy::Util
    attr_accessor :domrobot
    attr_accessor :object

    def initialize options = {}
      user = options[:user]
      passwd = options[:pass]
      addr = "api.domrobot.com"
      @object = "nameserver"
      @domrobot = INWX::Domrobot.new(addr)
      result = self.domrobot.login(user,passwd)
      super(options)
    end

    # create({ :fqdn => "node01.lab", :value => "192.168.100.2"}
    # create({ :fqdn => "node01.lab", :value => "3.100.168.192.in-addr.arpa",
    #          :type => "PTR"}
    def create
      method = "createRecord"
      #case @type
      #when "A"
      ip, id = dns_find(@fqdn)
      if ip
        raise(Proxy::Dns::Collision, "#{@fqdn} is already used") unless ip == @value
      else
        domain, name = split_fqdn(@fqdn)
        params = {:domain => domain, :type => @type, :content => @value, :name => name }
        result = self.domrobot.call(self.object, method, params)
        msg = "add #{@type} DNS entry #{name} => #{@value} to domain #{domain}"
        report msg, result["msg"], false
      end
      #end
    end

    # remove({ :fqdn => "node01.lab", :value => "192.168.100.2"}
    # remove({ :fqdn => "node01.lab", :value => "3.100.168.192.in-addr.arpa"}
    def remove
      #case @type
      #when "A"
      ip, id = dns_find(@fqdn)
      raise Proxy::Dns::NotFound.new("Cannot find DNS entry for #{@fqdn}") unless id
      msg = "remove DNS entry #{@fqdn} => #{@value}"
      method = "deleteRecord"
      params = { :id => id }
      result = self.domrobot.call(self.object, method, params)

      report msg, result["msg"], false
      #end
    end

    private
    
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
      domain = fqdn.split('.')[-2..-1].join('.')
      name = fqdn.chomp(".#{domain}")
      [domain,name]
    end

    def dns_find fqdn
      domain, name = split_fqdn(fqdn)
      method = "info"
      params = { :domain => domain, :name => name }
      logger.error params.inspect
      result = self.domrobot.call(self.object, method, params)
      logger.error result.inspect
      return false if result["resData"]["record"].nil?

      return [ result["resData"]["record"][0]["content"], result["resData"]["record"][0]["id"] ]
    end
  end
end
