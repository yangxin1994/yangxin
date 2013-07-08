# encoding: utf-8
class Sample::PrizesController < ApplicationController

  def get_prizes
    @prizes = Prize.where(:_id.in => params[:ids])
    render_json { @prizes }
  end

  	
end