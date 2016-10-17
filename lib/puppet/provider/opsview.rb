begin
  require 'rest-client'
  require 'json'
rescue LoadError => e
  nil
end
require 'yaml'

class Puppet::Provider::Opsview < Puppet::Provider
  @@errorOccurred = 0
  @@opsview_classvars = {
  	:calculated_total => 0,
	:total => 0,
	:seen => 0,
	:forked => false,
	:reload_opsview => false,
	:sleeptime => 10,
	:api_version => 0
  }

  def create
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      if val = resource.should(property)
        @property_hash[property] = val
      end
    end
  end

  def errorOccurred
    self.class.errorOccurred
  end
  
  def self.errorOccurred
    return true if @@errorOccurred > 0
    return false
  end

  def delete
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  private

  def internal
  	  if @@opsview_classvars[:calculated_total] == 0 && defined? resource.catalog.resources
		  [
		   Puppet::Type.type(:opsview_monitored),
		   Puppet::Type.type(:opsview_bsmservice),
		   Puppet::Type.type(:opsview_bsmcomponent),
		   Puppet::Type.type(:opsview_attribute),
		   Puppet::Type.type(:opsview_contact),
		   Puppet::Type.type(:opsview_hostgroup),
		   Puppet::Type.type(:opsview_hosttemplate),
		   Puppet::Type.type(:opsview_keyword),
		   Puppet::Type.type(:opsview_monitoringserver),
		   Puppet::Type.type(:opsview_notificationmethod),
		   Puppet::Type.type(:opsview_role),
		   Puppet::Type.type(:opsview_servicecheck),
		   Puppet::Type.type(:opsview_servicegroup),
		   Puppet::Type.type(:opsview_tenancy),
		  ].each do |type|
			@@opsview_classvars[:total] += resource.catalog.resources.find_all{ |x| x.is_a?(type) }.count
		  end
		  @@opsview_classvars[:calculated_total] = 1
  	end

	@@opsview_classvars[:seen] += 1

	if (@@opsview_classvars[:seen] == @@opsview_classvars[:total]) && @@opsview_classvars[:reload_opsview] == true
		Puppet.info "Forking a process to reload Opsview in #{@@opsview_classvars[:sleeptime]} seconds"
		@@opsview_classvars[:forked] = 1
		fork do
			sleep(@@opsview_classvars[:sleeptime])
			self.class.do_actual_reload_opsview
			exit
		end
	end
  end

  def put(body, type = 0)
    self.class.put(body, type)
  end

  def self.put(body, type = 0)
    if @@errorOccurred > 0
      Puppet.warning "put: Problem talking to Opsview server; ignoring Opsview config"
      return
    end

    url = [ config["url"], "config/#{@req_type.downcase}" ].join("/")
    begin
      if type == 1
        response = RestClient.post url, body, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json
      else
        response = RestClient.put url, body, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json
      end
    rescue
      @@errorOccurred = 1
      Puppet.warning "put_1: Problem sending data to Opsview server; " + $!.inspect + "\n====\n" + url + "\n====\n" + body
      return
    end

    begin
      responseJson = JSON.parse(response)
    rescue
      @@errorOccurred = 1
      Puppet.warning "put_2: Problem talking to Opsview server; ignoring Opsview config - " + $!.inspect
      return
    end

    # if we get here, all should be ok, so make sure we mark as such.
    @@errorOccurred = 0
  end

  def config
    self.class.config
  end

  def self.config
    Puppet.debug "Accessing config"
    @config ||= get_config
  end

  def self.get_config
    Puppet.debug "Loading in Opsview configuration"
    config_file = "/etc/puppet/opsview.conf"
    # Load the Opsview config
    begin
      conf = YAML.load_file(config_file)
    rescue
      raise Puppet::ParseError, "Could not parse YAML configuration file " + config_file + " " + $!.inspect
    end

    if conf["username"].nil? or conf["password"].nil? or conf["url"].nil?
      raise Puppet::ParseError, "Config file must contain URL, username, and password fields."
    end

    conf
  end

  def token
    self.class.token
  end

  def self.token
    Puppet.debug "Accessing token"
    @token ||= get_token
  end

  def self.get_token
    Puppet.debug "Fetching Opsview token"
    post_body = { "username" => config["username"],
                  "password" => config["password"] }.to_json

    url = [ config["url"], "login" ].join("/")

    Puppet.debug "Using Opsview url: "+url
    Puppet.debug "using post: username:"+config["username"]+" password:"+config["password"].gsub(/\w/,'x')

    if Puppet[:debug]
      Puppet.debug "Logging RestClient calls to: /tmp/puppet_restclient.log"
      RestClient.log='/tmp/puppet_restclient.log'
    end

    begin
      response = RestClient.post url, post_body, :content_type => :json
    rescue
      @@errorOccurred = 1
      Puppet.warning "Problem getting token from Opsview server; " + $!.inspect
      return
    end

    case response.code
    when 200
      Puppet.debug "Response code: 200"
    else
      @@errorOccurred = 1
      Puppet.warning "Unable to log in to Opsview server; HTTP code " + response.code
      return
    end

    received_token = JSON.parse(response)['token']
    Puppet.debug "Got token: "+received_token
    received_token
  end

  def do_reload_opsview
    self.class.do_reload_opsview
  end

  def self.get_api_status(method)
    url = [ config["url"], method ].join("/")

    Puppet.debug "Getting Opsview API status"

    response = RestClient.get url, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json

    case response.code
    when 200
        # all is ok at this pount
    when 401
        @@errorOccurred = 1
        raise "Login failed: " + response.code
    else
        @@errorOccurred = 1
        raise "Was not able to fetch Opsview status: HTTP code: " + response.code
    end
	
    Puppet.debug "Current API info: " + response.inspect
    return JSON.parse(response)
  end

  def self.do_actual_reload_opsview
    last_reload = self.get_api_status("reload")

    if last_reload["configuration_status"] == "uptodate"
	Puppet.info "Opsview is already up-to-date; exiting"
	return
    end

    if last_reload["server_status"].to_i > 0
        case last_reload["server_status"].to_i
	when 1
	    Puppet.info "Opsview reload already in progress; skipping"
	    return
	when 2
	    Puppet.warning "Opsview server is not running"
	    return
	when 3
	    Puppet.error "Opsview Server: Configuration error or critical error"
	    return
	when 4
	    Puppet.warning "Warnings exist in configuration:" + last_reload["messages"].inspect
	end
    end

    url = [ config["url"], "reload" ].join("/")

    if @@errorOccurred > 0
      Puppet.warning "reload_opsview: Problem talking to Opsview server; ignoring Opsview config"
      return
    end

    Puppet.notice "Performing Opsview reload"

    begin
      response = RestClient.post url, '', :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json, :params => {:asynchronous => 1}
    rescue
      @@errorOccurred = 1
      Puppet.warning "Unable to reload Opsview: " + $!.inspect
      return
    end

    case response.code
    when 200
      Puppet.debug "Reloaded Opsview"
    when 401
      raise "Login failed: " + response.code
    when 409
      Puppet.info "Opsview reload already in progress"
    else
      raise "Was not able to reload Opsview: HTTP code: " + response.code
    end

  end

  def self.do_reload_opsview
    @@opsview_classvars[:reload_opsview] = true
    if (@@opsview_classvars[:seen] == @@opsview_classvars[:total]) && @@opsview_classvars[:forked] == false
	self.do_actual_reload_opsview
    end
  end

  def get_resource(name = nil)
    self.class.get_resource(name)
  end

  def get_resources
    self.class.get_resources
  end

  def self.get_api_version
    if (@@opsview_classvars[:api_version] == 0)
      api_info = self.get_api_status("info")
      @@opsview_classvars[:api_version] = api_info["opsview_version"].to_f
    end

    @@opsview_classvars[:api_version]
  end
  
  def get_api_version
    self.class.get_api_version
  end

  def self.get_resource(name = nil)
    if @@errorOccurred > 0
      Puppet.warning "get_resource: Problem talking to Opsview server; ignoring Opsview config"
      return
    end

    if name.nil?
      raise "Did not specify a node to look up."
    else
      url = URI.escape( [ config["url"], "config/#{@req_type.downcase}?s.name=#{name}" ].join("/") )
    end
    
    self.get_api_version

    begin
      if @req_type == 'host' and @@opsview_classvars[:api_version] > 4.6
        response = RestClient.get url, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json, :params => {:rows => :all, :include_encrypted => 1, :cols => '+snmpinterfaces'}
      else
        response = RestClient.get url, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json, :params => {:rows => :all, :include_encrypted => 1}
      end
    rescue
      @@errorOccurred = 1
      Puppet.warning "get_resource: Problem talking to Opsview server; ignoring Opsview config: " + $!.inspect
    end

    begin
      responseJson = JSON.parse(response)
    rescue
      raise Puppet::Error,"Could not parse the JSON response from Opsview: " + response
    end

    obj = responseJson['list'][0]

    obj
  end

  def self.get_resources
    url = [ config["url"], "config/#{@req_type.downcase}" ].join("/")

    if @@errorOccurred > 0
       Puppet.warning "get_resources: Problem talking to Opsview server; ignoring Opsview config"
      return
    end

    self.get_api_version

    begin
      if @req_type == 'host' and @@opsview_classvars[:api_version] > 4.6
        response = RestClient.get url, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json, :params => {:rows => :all, :include_encrypted => 1, :cols => '+snmpinterfaces'}
      else
        response = RestClient.get url, :x_opsview_username => config["username"], :x_opsview_token => token, :content_type => :json, :accept => :json, :params => {:rows => :all, :include_encrypted => 1}
      end
    rescue
      @@errorOccurred = 1
      Puppet.warning "get_resource: Problem talking to Opsview server; ignoring Opsview config: " + $!.inspect
    end

    begin
      responseJson = JSON.parse(response)
    rescue
      raise "Could not parse the JSON response from Opsview: " + response
    end

    objs = responseJson["list"]

    objs
  end
end
