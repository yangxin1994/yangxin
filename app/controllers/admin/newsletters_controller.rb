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
    render :json  => @newsletters_client.test(params[:id], params[:email] ,params[:content])
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
      newsletter.deliver
    end    
  end

  def cancel
    render_json Newsletter.where(:_id => params[:id]).first do |newsletter|
      newsletter.cancel
    end        
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