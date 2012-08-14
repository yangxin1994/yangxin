class MessagesController < ApplicationController
  def index
    @messages = Message.all.page(page)
    @messages = ErrorEnum::MessgaeNotFound if @messages.empty? 
    respond_to do |format|
      format.json { render json: @messages }
    end
  end

  def create
    respond_to do |format|
      @message = current_user.create_message(params[:messages][:title],params[:messages][:content],params[:messages][:receiver])
      if @message.save
        format.json { render json: @message }
      else
        format.json { render json: false }
      end
    end
  end

  def update
    @message = Message.find_by_id(params[:messages][:id])
    respond_to do |format|
      @message = current_user.create_message(params[:messages][:title],params[:messages][:content],params[:messages][:receiver])
      if @message.save
        format.json { render json: @message }
      else
        format.json { render json: false }
      end
    end
  end

  def destroy
    @message = []
    params[:ids].to_a.each do |id|
      @message << (Message.find_by_id id do |r|
        r.delete
      end)
    end
    respond_to do |format|
      format.json { render json: @message }
    end
  end
               
end