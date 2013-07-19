# encoding: utf-8
class Sample::OrdersController < ApplicationController
  before_filter :require_sign_in

  def index
    @orders = @current_user.orders.where(:source => params[:source])
    render_json_auto auto_paginate @orders do |paginated_orders|
      paginated_orders.map { |e| e.info_for_sample }
    end
  end

end