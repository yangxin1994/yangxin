
require 'email'
require 'email_proxy'

module OopsMail
  module OopsMailJob
    extend EmailProxy

    #*params*: it receive a array, because resque job require it.
    # normally, you donot invoke it.
    # if you want to test the method, 
    # you should perform([{:account_name => "",
    #
    #   :account_secret => "",
    #
    #   :mail_list => [""],
    #
    #   :subject => "",
    #
    #   :content => "",
    #  
    #}])
    #
    def self.perform(*args)

      puts "OopsMailJob perform...."

      account_name = nil
      account_secret =nil
      mail_list =nil
      subject =nil
      content =nil
      mailler =nil
      api_key =nil
      api_domain =nil
      
      if args[0].class == Hash then
        arg = args[0]
        arg.each {|key, value| puts "#{key} : #{value}"}
        account_name = arg["account_name"]
        account_secret = arg["account_secret"]
        mail_list = arg["mail_list"]
        subject = arg["subject"]
        content = arg["content"]
        mailler = arg["mailler"]
        api_key = arg["api_key"]
        api_domain = arg["api_domain"]
      end

      if account_name.nil? || account_secret.nil? || mail_list.nil? || subject.nil? || content.nil? || mailler.nil? then
        raise ArgumentError, "Arguments is illegal."
      end

      #modify mailler logic
      temp_mailler = account_name.split("@")
      mailler = "netranking" if temp_mailler[1].include? "netranking"
      mailler = "gmail" if temp_mailler[1].include? "gmail"
      mailler = "mailgun" if temp_mailler[1].include? "mailgun"

      case mailler
      when "gmail"
        send_with_gmail :account_name => account_name,
                        :account_secret => account_secret,
                        :mail_list => mail_list,
                        :subject => subject,
                        :content => content
      when "mailgun"
        send_with_mailgun :account_name => account_name,
                          :mail_list => mail_list,
                          :subject => subject,
                          :content => content,
                          :api_key => api_key,
                          :api_domain => api_domain
      else
        send_with_netranking  :account_name => account_name,
                              :account_secret => account_secret,
                              :mail_list => mail_list,
                              :subject => subject,
                              :content => content
      end
    end
    
  end
end
