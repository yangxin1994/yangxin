# already tidied up
class Admin::NewslettersController < ApplicationController

  layout :resolve_layout

  def index
    @newsletters = auto_paginate Newsletter.find_by_status(params[:status])
  end

  def new
  end

  def show
    @newsletter = Newsletter.find(params[:id])
  end

  def edit
    @newsletter = Newsletter.find(params[:id]).present_admin
    @oops_column = @newsletter[:columns]['0']
    @pdct_column = @newsletter[:columns]['1']
    @columns = @newsletter[:columns].map do |order, column|
      column unless ['0', '1'].include? order
    end.compact

  end

  def test
    render_json Newsletter.where(:_id => params[:id]).first do |newsletter|
      newsletter.deliver_test_news(params[:content], "#{request.protocol }#{ request.host_with_port }", "", params[:email])
    end   
  end

  def create
    # @newsletter  = @newsletters_client.create(
    #   :subject => params[:subject],
    #   :status  => params[:status],
    #   :subject => params[:subject],
    #   :content => params[:content],
    #   )
    render_json Newsletter.create(params[:newsletter])
  end

  def update
    render_json Newsletter.where(:_id => params[:id]).first do |newsletter|
      newsletter.update_attributes(params[:newsletter])
    end
  end

  def destroy
    render_json Newsletter.where(:_id => params[:id]).first do |newsletter|
      newsletter.update_attributes(:is_deleted => true)
    end
  end

  def column
    render :partial => 'admin/newsletters/template/column', :locals => params
  end

  def article
    render :partial => 'admin/newsletters/template/article', :locals => params
  end

  def product_news
    render :partial => 'admin/newsletters/template/product_news', :object => params[:article]
  end

  def deliver
    render_json Newsletter.where(:_id => params[:id]).first do |newsletter|
      newsletter.deliver_news(content_html, "#{ request.protocol }#{ request.host_with_port }", "")
    end    
  end

  def cancel
    render_json Newsletter.where(:_id => params[:id]).first do |newsletter|
      newsletter.cancel
    end        
  end

  def netranking_newsletter
    @file_path = params[:path]
  end

  def upload_attachment
  end

  def attachment_uploaded
    name =  params[:file].original_filename
    directory = "public/uploads/magzine"
    # create the file path
    path = File.join(directory, name)
    # write the file
    File.open(path, "wb") { |f| f.write(params[:file].read) }
    redirect_to action: :netranking_newsletter, path: path
  end

  def send_netranking_newsletter
    if params[:email_list].to_s == "true"
      emails = params[:email_content].split("\n")
    else
      emails = NetrankingUser.all.map { |e| e.email }
    end
    send_from = params[:send_from].blank? ? "postmaster@#{params[:domain]}" : params[:send_from]
    MailgunApi.send_emagzine(params[:subject], send_from, params[:domain], params[:content], params[:file_path], emails)
    render_json_auto and return
  end

  private

  def resolve_layout
    case action_name
    when "new", "show", "edit"
      "layouts/newsletter"
    else
      "layouts/admin-todc"
    end
  end
end
