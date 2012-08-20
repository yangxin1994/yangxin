# coding: utf-8

module OopsMail

  class EmailSender

    attr_accessor :username, :email, :password, :api_key, :api_domain

    #*params*:
    #
    #* username: the receiver name which would be show in mail's receiver.
    #* email: the receiver email address 
    #which would be show in mail's receiver and email destination for sending.
    #* password: the email password which you type in before.
    #* api_key: just for mailgun api key
    #* api_domain: just for mailgun api domain
    def initialize(username, email, password, api_key=nil, api_domain=nil)
      if (email=~/^[A-Za-z0-9](([_\.\-]?[a-zA-Z0-9]+)*)@([A-Za-z0-9]+)(([\.\-]?[a-zA-Z0-9]+)*)\.([A-Za-z]{2,})$/).nil? then
        raise ArgumentError, "The sender email address: #{email} is illegal." 
      end
      @username = username
      @email = email    
      @password = password
      @api_key = api_key
      @api_domain = api_domain
    end

    # redefine to_s method
    def to_s
      if @api_key.nil? then
        "#{@username} 's email #{@email}, the pwd is #{@password}"
      else
        "#{@username} 's email #{@email}, the pwd is #{@password}, api_key is #{@api_key}, api_domain is #{api_domain}"
      end
    end    
  end
end
