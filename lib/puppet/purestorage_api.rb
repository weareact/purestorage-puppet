#=====================================
#This class  is  mainly used for 
#REST API 1.12 for Pure Storage Array
#It will have utility methods 
#to perform CRUD operations on 
#Volume and Host and creating 
#connection between them. 
#
# Supports REST API 1.12
#=====================================

require 'net/https'
require 'uri'
require 'json'
require 'puppet/cacheservice'

class PureStorageApi

  CONTENT_TYPE        = "Content-Type"
  APPLICATION_JSON    = "application/json"
  COOKIE              = "Cookie"
  TOKEN               = "TOKEN"
  SESSION_KEY         = "SESSION_KEY"
  REST_VERSION        = "1.12"
  CREATE              = "create"
  UPDATE              = "update"
  DELETE              = "delete"
  LIST                = "list"

  # -----------------------------------------------------------------------------------
  # Constructor
  # -----------------------------------------------------------------------------------
  def initialize(device_ip, username, password, rest_version)
    @device_ip     = device_ip
    @username      = username
    @password      = password
    @rest_version  = rest_version
    @base_uri      = "https://" + device_ip + "/api/" + rest_version
    @cache_service = CacheService.new(device_ip)

    #Delete Cache if its expired.
    if @cache_service.has_cache_expired
      # puts "Cache is expired, hence deleting file :" + @deviceIp
      Puppet.debug "Cache is expired, hence deleting file :" + @device_ip
      @cache_service.delete_cache
    end
  end

  def make_rest_api_call(request, session_header = true, parse_response = true)
    # Create the HTTP objects
    uri = URI.parse(@base_uri)
    http             = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request.add_field(CONTENT_TYPE, APPLICATION_JSON)
    if session_header
      request.add_field(COOKIE, get_session)
    end

    begin
      # Send the request and parse response
      Puppet.debug("Making REST Request: #{request.inspect}")
      response = http.request(request)
      if parse_response
        json_response = JSON.parse(response.body)
        Puppet.debug("Received JSON Response: #{json_response.inspect}")
        return json_response
      else
        Puppet.debug("Received Response: #{response.inspect}")
        return response
      end
    rescue Exception
      Puppet.err("Device '" + @device_ip + "' is either not reachable or down!!!")
      #raise Exception
    end
  end

  #------------------------------------------------------------------------------------
  # Step 1 : Create Token 
  # e.g.
  # POST    https://m70.purecloud.local/api/1.12/auth/apitoken
  #
  # This method returns token generated by REST server which is used to create session
  #------------------------------------------------------------------------------------
  def create_token
    token = nil

    begin
      token = @cache_service.read_cache(TOKEN)
      Puppet.debug("Found Token : " + token)
    rescue
      Puppet.debug("Looks like token is not cashed earlier or some other issue!")
    end

    if token == nil
      uri = URI.parse(@base_uri + "/auth/apitoken")

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data('password' => @password, 'username' => @username)

      response = make_rest_api_call(request, false)

      token = response['api_token']
      @cache_service.write_cache(TOKEN, token)
    end

    token
  end

  #----------------------------------------------------------------------------
  #Step 2: Create session by passing token obtained in createToken method
  # e.g.
  # POST     https://m70.purecloud.local/api/1.12/auth/session
  #
  # This method returns session key which will be used in further rest calls
  #----------------------------------------------------------------------------
  def create_session (token)
    session_key = nil

    begin
      session_key = @cache_service.read_cache(SESSION_KEY)
      Puppet.debug("Found session_key : " + session_key)
    rescue
      Puppet.debug("Looks like session is not cached earlier or some other issue!")
    end

    if session_key == nil
      uri = URI.parse(@base_uri + "/auth/session")

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data('api_token' => token)

      response = make_rest_api_call(request, false, false)

      session_key = response.header['Set-Cookie']
      @cache_service.write_cache(SESSION_KEY, session_key)
    end
    session_key
  end

  #-------------------------------------------------
  # This method calls creates (token and session)
  # e.g.
  #   https://pure01.example.com/api/1.12/volume
  # return generated session 
  #-------------------------------------------------
  def get_session
    token = create_token
    if token == nil
      raise "Unable to create a token for device: " + @device_ip + ". Please check the credentials or device Ip Address provided in the url!"
    else
      session = create_session(token)
    end

    session
  end

  #-------------------------------------------------
  # Generic method for GET requests
  # e.g.
  # GET  https://pure01.example.com/api/1.12/volume
  #-------------------------------------------------
  def get_rest_call(arg_url)
    uri = URI.parse(@base_uri + arg_url)

    request = Net::HTTP::Get.new(uri.request_uri)

    make_rest_api_call(request)
  end

  #-------------------------------------------------
  # Generic method for POST requests 
  # e.g.
  # POST https://pure01.example.com/api/1.12/volume/v5
  # {
  #   "size": "5G"
  # }
  #-------------------------------------------------
  def post_rest_call(arg_url, arg_body)
    uri = URI.parse(@base_uri + arg_url)

    request          = Net::HTTP::Post.new(uri.request_uri)
    request.body     = arg_body.to_json

    make_rest_api_call(request)
  end

  #-------------------------------------------------
  # Generic method for PUT requests
  # e.g.
  # PUT https://pure01.example.com/api/1.12/volume/v5
  #  {
  #    size: 10G
  #  }
  #-------------------------------------------------
  def put_rest_call(arg_url, arg_body)
    uri = URI.parse(@base_uri + arg_url)

    request          = Net::HTTP::Put.new(uri.request_uri, header)
    request.body     = arg_body.to_json

    make_rest_api_call(request)
  end

  #-------------------------------------------------
  # Generic method for DELETE requests
  # e.g.
  # DELETE https://pure01.example.com/api/1.12/volume/v5
  #-------------------------------------------------
  def delete_rest_call(arg_url)

    uri = URI.parse(@base_uri + arg_url)

    request          = Net::HTTP::Delete.new(uri.request_uri, header)

    make_rest_api_call(request)
  end

  #----------------------------------------------------
  # This method checks if volume with given name exists
  #  It is dedicated to volumes
  #-----------------------------------------------
  def does_volume_exist(arg_volume_name)
    url    = "/volume/" + arg_volume_name
    output = get_rest_call(url)

    output["pure_err_key"] == nil
  end


  #-------------------------------------------------
  # Its a controller method which decides 
  # which rest api to call depending on key
  # It is dedicated to volumes
  #-----------------------------------------------
  def execute_volume_rest_api(arg_key, *arg)
    Puppet.info(arg_key + " Action for volume:" + arg[0])
    case arg_key
    when LIST then
      get_rest_call("/volume")
    when CREATE then #arg[0] = volume_name, arg[1] = volume_size
      url  = "/volume/" + arg[0]
      body = Hash.new("size" => arg[1])
      post_rest_call(url, body["size"])
    when UPDATE then
      url  = "/volume/" + arg[0]
      body = Hash.new("size" => arg[1])
      put_rest_call(url, body["size"])
    when DELETE then
      url = "/volume/" + arg[0]
      delete_rest_call(url)
    else
      Puppet.err("Invalid Operation:" + arg_key + ", Available operations are [create,update,delete,list].")
    end
  end

  #----------------------------------------------------
  # This method checks if volume with given name exists
  # It is dedicated to hosts
  #-----------------------------------------------
  def does_host_exist(arg_host_name)
    url    = "/host/" + arg_host_name
    output = get_rest_call(url)

    output["pure_err_key"] == nil
  end

  #-------------------------------------------------
  # Its a controller method which decides
  # which rest api to call depending on key
  # It is dedicated to Hosts
  #-----------------------------------------------
  def execute_host_rest_api(arg_key, *arg)
    Puppet.info(arg_key + " Action for host:" + arg[0])
    case arg_key
    when LIST then
      get_rest_call("/host")
    when CREATE then #arg[0] = volume_name, arg[1] = volume_size
      url  = "/host/" + arg[0]
      body = Hash.new("iqnlist" => arg[1], "wwnlist" => arg[2])
      post_rest_call(url, body)
    when UPDATE then
      url  = "/host/" + arg[0]
      body = Hash.new("iqnlist" => arg[1], "wwnlist" => arg[2])
      put_rest_call(url, body)
    when DELETE then
      url = "/host/" + arg[0]
      delete_rest_call(url)
    else
      Puppet.err("Invalid Option:" + arg_key)
    end
  end

  #----------------------------------------------------
  # This method checks if connection with given name exists
  # It is dedicated to volumes
  # -----------------------------------------------
  def does_connection_exist(arg_host_name)
    url    = "/host/" + arg_host_name + "/volume"
    output = get_rest_call(url)

    output["vol"] != nil
  end

  #-------------------------------------------------
  # Its a controller method which decides 
  # which rest api to call depending on key
  # It is dedicated to Hosts
  # arg[0] = hostname, arg[1] = volumename
  #-----------------------------------------------
  def execute_connection_rest_api(arg_key, *arg)
    Puppet.info(arg_key + " Action for connection between host :" + arg[0] + " and volume:" + arg[1])
    case arg_key
    when CREATE then #arg[0] = volume_name, arg[1] = volume_size
      url = "/host/" + arg[0] + "/volume/" + arg[1]
      post_rest_call(url, "")
    when DELETE then
      url = "/host/" + arg[0] + "/volume/" + arg[1]
      delete_rest_call(url)
    else
      Puppet.err("Invalid Option:" + arg_key)
    end
  end
end
