# coding: utf-8

module OopsMail

	#can not name with Mail, it will fight with Rails3's Mail.
  class OMail

    attr_reader :subject, :content, :type

    #*params*:
    #
    #* subject: mail's subject
    #* content: mail's content
    #* type: mail's type which includes "text" and "html(text/html)". Default is html. No use!
    def initialize(subject, content, type="html")
      @subject = subject
      @content = content
		  @type = type	
    end
  end

  
end
