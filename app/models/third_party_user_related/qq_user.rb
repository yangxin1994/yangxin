# coding: utf-8
class QqUser < ThirdPartyUser

  field :nickname, :type => String
  field :gender, :type => String # male will return: "男"
  field :figureurl, :type => String

  alias name nickname  

  #get access_token for other works
  #
  #*params*:
  #
  #*code: code from third party respond.
  #
  #*retval*:
  #
  #* response_data: it includes access_token, expires_in
  def self.get_access_token(code, redirect_uri)
        access_token_params = {"client_id" => OOPSDATA[Rails.env]["qq_app_id"],
            "client_secret" => OOPSDATA[Rails.env]["qq_app_key"],
            "redirect_uri" => redirect_uri || OOPSDATA[Rails.env]["qq_redirect_uri"],
            "grant_type" => "authorization_code",
            "state" => Time.now.to_i,
            "code" => code}
        retval = Tool.send_post_request("https://graph.qq.com/oauth2.0/token", access_token_params, true)
        access_token, expires_in = *(retval.body.split('&').map { |ele| ele.split('=')[1] })
        #Logger.new("log/development.log").info(retval.body.to_s)
        
        response_data = {"access_token" => access_token, "expires_in" => expires_in}        
        return response_data
  end
 
  # receive params, then 
  #
  # 1. get user_id through access_token
  #
  # 2. new or update qq_user
  #
  #*params*: 
  #
  #* response_data: access_token, expires_in
  #
  #*retval*:
  #
  #*qq_user: new or updated.
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
    #Logger.new("log/development.log").info("tp_user1 : "+qq_user.to_s)
    if qq_user.nil? then
      qq_user = QqUser.new(:website => "qq", :website_id => website_id, :access_token => access_token)
      qq_user.save
    else
      #qq_user.update_by_hash(response_data)
    end

    # qq_user.update_user_info

    return qq_user
  end

  def locale
    nil
  end
 
  #*description*: it can call any methods from third_party's API:
  #http://wiki.opensns.qq.com/wiki/%E3%80%90QQ%E7%99%BB%E5%BD%95%E3%80%91API%E6%96%87%E6%A1%A3
  #
  #*params*:
  #
  #*opts: hash.
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

  alias get_user_info call_method
 
  #*description*: update user base info, it involves get_user_info.
  #
  #*params*: none
  #
  #*retval*:
  #* instance: a updated qq user.
  def update_user_info
    @select_attrs = %{nickname gender figureurl}
    super
  end

  #*description*: add share of a link information.
  #API: http://wiki.opensns.qq.com/wiki/%E3%80%90QQ%E7%99%BB%E5%BD%95%E3%80%91add_share
  #
  #*params*: 
  #* title: the share info's title
  #* url: the place which click the info to turn
  #* comment: what you say with the share. default is nil.
  #* summary: a short info of the share. default  is nil.
  #* images: a image's link. default is nil.
  #
  #*retval*:
  #
  # say successfully or not.
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
