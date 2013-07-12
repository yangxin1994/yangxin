# encoding: utf-8
class Sample::PrizesController < ApplicationController

  def get_prizes
    @prizes = Prize.where(:_id.in => params[:ids])
    render_json { @prizes }
  end

  def show
  	@prize = Prize.find_by_id(:id)
  	render_json_e ErrorEnum::PRIZE_NOT_EXIST and return if @prize.nil?
  	render_json_auto @prize and return
  end
end