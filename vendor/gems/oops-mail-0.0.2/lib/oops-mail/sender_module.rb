require 'resque_scheduler'

module OopsMail
  module SenderModule
      

    @sender_list = []

    #Get all sender from db
    def get_sender_list
      server_db = Resque.redis
    
      puts "get_sender_list : " + server_db.exists("senders").to_s

      raise ArgumentError, "Dont get the sender list from redis." if !server_db.exists("senders")

      sender_ids = server_db.smembers "senders"
      @sender_list = nil
      @sender_list = []
      sender_ids.each do |id| 
        username = server_db.get "sender:#{id}:username" 
        email = server_db.get "sender:#{id}:email"
        password = server_db.get "sender:#{id}:password"
        if !username.nil? && !email.nil? && password.nil? then  
          @sender_list.push({:username => username, :email => email, :password => password}) 
        end
      end

      @sender_list
    rescue => ex 
      raise ex
    end

    #Get a sender for random from db
    def rand_sender
      server_db = Resque.redis
      
      puts "rand_sender : " + server_db.exists("senders").to_s
      raise ArgumentError, "Dont get the sender list from redis." if !server_db.exists("senders")

      sender_ids = server_db.smembers "senders"
      len = sender_ids.length
      if len > 0 then
        rand_id = rand(len)
        id = sender_ids[rand_id]
        while !(server_db.exists "sender:#{id}:email") do
          rand_id = rand(len)
          id = sender_ids[rand_id]
        end

        email = server_db.get "sender:#{id}:email"
        username = server_db.get "sender:#{id}:username"
        password = server_db.get "sender:#{id}:password"

        if !email.nil? and !password.nil?
          OopsMail::EmailSender.new(username, email, password) 
        else
          nil
        end
      else 
        nil
      end      
    rescue => ex 
      raise ex
    end
  end
end
