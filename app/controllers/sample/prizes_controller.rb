# encoding: utf-8
class Sample::PrizesController < ApplicationController

  def get_prizes
    @prizes = Prize.where(:_id.in => params[:ids].split(','))
    @prizes = @prizes.map{|prize| prize['photo_src'] = prize.photo.present? ? prize.photo.picture_url : Prize::DEFAULT_IMG;prize }
    render_json_auto(@prizes)
  end

  	
end