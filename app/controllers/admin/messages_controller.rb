class Admin::MessagesController < Admin::AdminController

  layout 'admin_new'

  # ************************
  
  # GET
  def index

    receiver = User.find_by_email(params[:receiver_email])
    @messages = auto_paginate Message.where(:receiver_ids => receiver._id) do |messages|
      message['receiver_emails'] = []
      message['receiver_ids'].each do |rec_id|
        receiver = User.find_by_id_including_deleted(rec_id)
        message['receiver_emails'] << receiver.email if receiver
      end
      
      sender=User.find_by_id_including_deleted(message['sender_id'].to_s)
      message['sender_email'] = sender.email if sender
      message
    end
  end

  def show
    @message = @client._get({},"/#{params[:id]}")
    respond_to do |format|
      format.html
      format.json { render json: @message}
    end
  end

  #post
  def create
    receiver = params[:receiver].split(',').each{|v| v.strip!}
    @result = @client._post({
    :message => {
        :title => params[:title],
        :content => params[:content],
        :receiver => receiver
      }
    })

    render_result
  end

  # put
  def update
    receiver = params[:receiver].split(',').each{|v| v.strip!}
    @result = @client._put({
    :message => {
        :title => params[:title],
        # :receiver => receiver,
        :content => params[:content]
      }
    }, "/#{params[:id]}")
    render_result
  end

  #delete
  def destroy
    @result = @client._delete({}, "/#{params[:id]}")
    render_result
  end

end