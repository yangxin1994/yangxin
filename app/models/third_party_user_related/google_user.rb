class GoogleUser < ThirdPartyUser

  field :name, :type => String
  field :gender, :type => String #male will return: "male"
  field :locale, :type => String
  field :google_email, :type => String  

  alias get_user_info call_method

  public

  def self.get_access_token(code, redirect_uri)
    #get access_token
    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["google_client_id"],
      "client_secret" => OOPSDATA[Rails.env]["google_client_secret"],
      "redirect_uri" => redirect_uri,
      "grant_type" => "authorization_code",
      "code" => code
    }
    retval = Tool.send_post_request("https://accounts.google.com/o/oauth2/token", access_token_params, true)
    response_data = JSON.parse(retval.body)
    return response_data
  end

  def self.save_tp_user(response_data)
    access_token = response_data["access_token"]
    retval = Tool.send_get_request("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{access_token}", true)    
    response_data2 = JSON.parse(retval.body)        
    return false if !response_data2.select{|k,v| k.to_s.include?("error")}.empty?
    
    website_id = response_data2["id"]
    
    # reject the same function field
    response_data["google_email"] = response_data2["email"]
    response_data2.select!{|k,v| !k.to_s.include?("id") && k.to_s !="email" }
    
    # merge info
    response_data.merge!(response_data2).select!{|k,v| !k.to_s.include?("id") }
    #select info 
    attrs = %{access_token refresh_token expires_in name gender locale google_email}
    response_data.select!{|k,v| attrs.split.include?(k.to_s)}
    
    #new or update google_user
    google_user = GoogleUser.where(:website_id => website_id)[0]
    if google_user.nil?
        response_data.merge!({"website"=>"google", "website_id" => website_id })
        google_user = GoogleUser.new(response_data)
        google_user.save
    end
    
    return google_user
  end


  def call_method(http_method="get", opts = {:method => "userinfo"})
    @params={}
    @params[:access_token] = self.access_token
    method = opts[:method] || opts["method"]
    
    if http_method.downcase == "get"
     params_string = generate_params_string(opts)
     retval = Tool.send_get_request("https://www.googleapis.com/oauth2/v1/#{method}#{params_string}", true) 
    else
      opts.merge!(@params).select!{|k,v| k.to_s != "method"}
      retval = Tool.send_post_request("https://www.googleapis.com/oauth2/v1/#{method}", opts, true)
    end
    return JSON.parse(retval.body)
  end

  def update_user_info
    @select_attrs = %{name gender locale google_email}
    super
  end
end
