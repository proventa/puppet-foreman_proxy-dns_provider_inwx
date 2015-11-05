require 'resolv'
require 'resolv-replace'
require_relative 'inwx/Domrobot'
require 'yaml'

module Proxy::Dns
  class Inwx < Record
    include Proxy::Log
    include Proxy::Util
    attr_reader :resolver
    attr_accessor :domrobot
    attr_accessor :object
    
    def initialize options = {}
      user = Proxy::Dns::Plugin.settings.dns_user
      pass = Proxy::Dns::Plugin.settings.dns_password
      addr = "api.domrobot.com"
      @object = "nameserver"
      @domrobot = INWX::Domrobot.new(addr)
      result = self.domrobot.login(user,pass)
      super(options)
    end

    # create({ :fqdn => "node01.lab", :value => "192.168.100.2"}
    # create({ :fqdn => "node01.lab", :value => "3.100.168.192.in-addr.arpa",
    #          :type => "PTR"}
    def create
      @resolver = Resolv::DNS.new(:nameserver => @server)
      method = "createRecord"
      #case @type
      #when "A"
      if ip = dns_find(@fqdn)
        raise(Proxy::Dns::Collision, "#{@fqdn} is already used by #{ip}") unless ip == @value
      else
        domain = @fqdn.sub(/[^.]+./,'')
        params = { :domain => domain, :type => @type, :content => @value, :name => @fqdn }
        result = self.domrobot.call(self.object, method, params)
        msg = "Added DNS entry #{@fqdn} => #{@value}"
        report msg, result["msg"], false
      end 
      #end
    end

    # remove({ :fqdn => "node01.lab", :value => "192.168.100.2"}
    # remove({ :fqdn => "node01.lab", :value => "3.100.168.192.in-addr.arpa"}
    def remove
      @resolver = Resolv::DNS.new(:nameserver => @server)
      #case @type
      #when "A"
      raise Proxy::Dns::NotFound.new("Cannot find DNS entry for #{@fqdn}") unless dns_find(@fqdn)
      msg = "Removed DNS entry #{@fqdn} => #{@value}"
      method = "info"
      domain = @fqdn.sub(/[^.]+./,'')
      params = { :domain => domain, :name => @fqdn }
      result = self.domrobot.call(self.object, method, params)
      
      method = "deleteRecord"
      ids = result["resData"]["record"]
      if ids.nil?
        report msg, "completed successfully: no DNS entry available to delete", false
        return true
      end

      params = { :id => ids[0]["id"] }
      result = self.domrobot.call(self.object, method, params)
      
      report msg, result["msg"], false
      #end
    end

    private

    def report msg, response, error_only=false
      if not response.include? "completed successfully"
        logger.error "Inwx failed:\n" + response.join("\n")
        msg.sub! /Removed/,    "remove"
        msg.sub! /Added/,      "add"
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

    def dns_find key
      if match = key.match(/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/)
        resolver.getname(match[1..4].reverse.join(".")).to_s
      else
        resolver.getaddress(key).to_s
      end
    rescue Resolv::ResolvError
      false
    end
  end
end
