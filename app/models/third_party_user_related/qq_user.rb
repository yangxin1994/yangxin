# coding: utf-8
class QqUser < ThirdPartyUser

  field :nickname, :type => String
  field :gender, :type => String # male will return: "男"
  field :figureurl, :type => String

  alias name nickname  
  alias get_user_info call_method

  def self.get_access_token(code, redirect_uri)
    access_token_params = {
      "client_id" => OOPSDATA[Rails.env]["qq_app_id"],
      "client_secret" => OOPSDATA[Rails.env]["qq_app_key"],
      "redirect_uri" => redirect_uri || OOPSDATA[Rails.env]["qq_redirect_uri"],
      "grant_type" => "authorization_code",
      "state" => Time.now.to_i,
      "code" => code
    }
    retval = Tool.send_post_request("https://graph.qq.com/oauth2.0/token", access_token_params, true)
    access_token, expires_in = *(retval.body.split('&').map { |ele| ele.split('=')[1] })
    
    response_data = {"access_token" => access_token, "expires_in" => expires_in}        
    return response_data
  end
 
  def self.save_tp_user(response_data)
    access_token = response_data["access_token"]
    expires_in = response_data["expires_in"]
    #get user_id through access_token
    retval = Tool.send_get_request("https://graph.qq.com/oauth2.0/me?access_token=#{access_token}", true)
    #Logger.new("log/development.log").info("save_tp_user: "+retval.body.to_s)
    response_data2 = JSON.parse(retval.body.split(' ')[1])
    
    website_id = response_data2["openid"]

    # reject the same function field
    response_data.select!{|k,v| !k.to_s.include?("id") }
    response_data2.select!{|k,v| !k.to_s.include?("id") }
    
    # merge info
    response_data.merge!(response_data2)
    
    #new or update qq_user
    qq_user = QqUser.where(:website_id => website_id)[0]

    if qq_user.nil?
      qq_user = QqUser.new(:website => "qq", :website_id => website_id, :access_token => access_token)
      qq_user.save
    end

    return qq_user
  end

  def locale
    nil
  end
 
  def call_method(http_method="get", opts = {:method => "user/get_user_info"})

    @params={}
    @params[:access_token] = self.access_token
    @params[:oauth_consumer_key] = OOPSDATA[Rails.env]["qq_app_id"]
    @params[:openid] = self.user_id
    method = opts[:method] || opts["method"]
    
    if http_method.downcase == "get" then
      params_string = generate_params_string(opts)
      retval = Tool.send_get_request("https://graph.qq.com/#{method}#{params_string}", true)
    else
      opts.merge!(@params).select!{|k,v| k.to_s != "method"}      
      retval = Tool.send_post_request("https://graph.qq.com/#{method}", opts, true)
    end
    return JSON.parse(retval.body)
  end

  def update_user_info
    @select_attrs = %{nickname gender figureurl}
    super
  end

  def add_share(title, url, comment=nil, summary=nil, images=nil)
    opts = {}
    opts["method"] = "share/add_share"
    opts["title"] = title
    opts["url"] = url
    opts["comment"] = comment if comment
    opts["summary"] = summary if summary
    opts["images"] = images if images
    retval = call_method("post", opts)
    
    ##successful?(retval)
    retval["ret"].to_i == 0 
  end

end
