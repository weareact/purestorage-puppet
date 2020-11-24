require 'puppet/util/network_device'
require_relative 'facts'
require 'uri'
require 'purest'

class Puppet::Util::NetworkDevice::Pure::Device

  attr_accessor :api_version, :url

  def initialize(url, options = {})
    @url = URI.parse(url)
    Puppet.debug("URL = #{@url.inspect}")
    redacted_url = @url.dup
    redacted_url.password = "****" if redacted_url.password

    Puppet.debug("Puppet::Device::Pure: connecting to Pure array: #{redacted_url} using API version 1.12")

    raise ArgumentError, "invalid scheme #{@url.scheme}. Must be https" unless @url.scheme == 'https'
    raise ArgumentError, "no user specified" unless @url.user
    raise ArgumentError, "no password specified" unless @url.password

    Purest.configure do |config|
      config.api_version = '1.12'
      config.options     = {ssl: {verify: false}}
      config.password    = @url.password
      config.url         = "https://#{@url.host}"
      config.username    = @url.user
    end

    self.api_version = '1.12'

  end

  def facts
    Puppet.debug("Inside Device FACTS Initialize URL :" + @url.to_s)
    @facts ||= Puppet::Util::NetworkDevice::Pure::Facts.new
    Puppet.debug("After creating FACTS Object !!!")
    @facts.retrieve
  end

end
