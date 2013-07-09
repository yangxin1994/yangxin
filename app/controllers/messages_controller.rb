require 'error_enum'
class MessagesController < ApplicationController
	
  before_filter :require_sign_in

  def index
    @messages = auto_paginate current_user.show_messages
    render_json { @messages }
  end
  
  def unread_count
    render_json { current_user.unread_messages_count }
  end

  def get_my_sys_notice
  	m = Message.any_of({:type => 0},{:recriver_ids => ["#{@current_user.id}"]})
  	m = auto_paginate(m)
  	render_json{m}
  end 

end
