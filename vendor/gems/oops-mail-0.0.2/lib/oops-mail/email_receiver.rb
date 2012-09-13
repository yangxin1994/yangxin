# coding: utf-8

module OopsMail

  class EmailReceiver

    attr_reader :username, :email

    #*params*:
    #
    #* username: the receiver name which would be show in mail's receiver.
    #* email: the receiver email address 
    #which would be show in mail's receiver and email destination for sending.
    def initialize(username, email)
      if (email=~/^[A-Za-z0-9](([_\.\-]?[a-zA-Z0-9]+)*)@([A-Za-z0-9]+)(([\.\-]?[a-zA-Z0-9]+)*)\.([A-Za-z]{2,})$/).nil? then
        raise ArgumentError, "The receiver email address: #{email} is illegal." 
      end
      @username = username
      @email = email    
    end

    #redefine to_s method
    def to_s
      "#{username}'s email is #{email}. "
    end
  end
end
