class Admin::MessagesController < Admin::ApplicationController

  def index
    @messages = Message.all.page(page)
    #@messages = ErrorEnum::MessgaeNotFound if @messages.empty?
    respond_and_render_json { @messages.as_retval }
  end

  def create
    respond_to do |format|
      @message = current_user.create_message(params[:messages][:title],params[:messages][:content],params[:messages][:receiver])
      respond_and_render_json @message.save { @message.as_retval }
      end
    end
  end

  def update
    @message = Message.find_by_id(params[:messages][:id])
    respond_to do |format|
      @message = current_user.create_message(params[:messages][:title],params[:messages][:content],params[:messages][:receiver])
      respond_and_render_json @message.save { @messages.as_retval}
  end

  def destroy
    @messages = []
    params[:ids].to_a.each do |id|
      @messages << (Message.find_by_id id do |r|
        r.delete
      end)
    end
    respond_and_render_json{ @messages }
  end
               
end