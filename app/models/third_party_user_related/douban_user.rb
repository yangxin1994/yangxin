require 'net'
class DoubanUser < ThirdPartyUser

    field :name, :type => String

    #*description*: get access_token for other works
    #
    #*params*:
    #* code: code from third party respond.
    #
    #*retval*:
    #* response_data: it includes access_token, expires_in and user info
    def self.get_access_token(code, redirect_uri)
        access_token_params = {"client_id" => OOPSDATA[RailsEnv.get_rails_env]["douban_api_key"],
            "client_secret" => OOPSDATA[RailsEnv.get_rails_env]["douban_secret_key"],
            "redirect_uri" => redirect_uri,
            "grant_type" => "authorization_code",
            "code" => code}
        retval = Tool.send_post_request("https://www.douban.com/service/auth2/token", access_token_params, true)
        response_data = JSON.parse(retval.body)
        return response_data
    end

    #*description*: receive params, then
    #
    # 1. new or update douban_user
    #
    #*params*: 
    #* response_data: access_token, user_id and other
    #
    #*retval*:
    #* douban_user: new or updated.
    def self.save_tp_user(response_data)
        
        access_token = response_data["access_token"]
        refresh_token = response_data["refresh_token"]
        expires_in = response_data["expires_in"]
        website_id = response_data["douban_user_id"]

        #new or update douban_user
        douban_user = DoubanUser.where(:website_id => website_id)[0]
        if douban_user.nil?
            douban_user = DoubanUser.new(:website => "douban", :website_id => website_id, :access_token => access_token, 
            :refresh_token => refresh_token, :expires_in => expires_in)
            douban_user.save
        else 
            #only update access_token, refresh_token, expires_in, remove other info which is un-useful.
            response_data = {}
            response_data["access_token"] = access_token 
            response_data["refresh_token"] = refresh_token
            response_data["expires_in"] = expires_in
            # update info 
            #douban_user.update_by_hash(response_data)
        end
        
        return douban_user
    end

    #*description*: get user base info, it involves call_method.
    #
    #*params*: none
    #
    #*retval*:
    #
    # a hash data
    def get_user_info
        # if not a array, it should be error for user login.
        call_method()[0]
    end

    #*description*: get user base info, it involves get_user_info.
    #
    #*params*: none
    #
    #*retval*:
    #* instance: a updated renren user.
    def update_user_info
        @select_attrs = %{name sex headurl}
        super
    end

end
