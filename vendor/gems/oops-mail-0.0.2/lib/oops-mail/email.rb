# coding: utf-8

require 'omail'
require 'email_sender'
require 'email_receiver'

module OopsMail

  class Email

    attr_reader :sender, :receiver, :mail

    #*params*:
    #
    #* sender: EmailSender object.
    #* receiver: EmailReceiver Array.
    #* omail: OMail object.
    def initialize(sender=nil, receiver, omail)

      @receiver = []
      if receiver.instance_of? EmailReceiver then
        @receiver.push receiver
      end
      if receiver.instance_of? Array then
        @receiver = receiver
      end
      
      @sender = sender
		  @mail = omail	
    end
  end
  
end
