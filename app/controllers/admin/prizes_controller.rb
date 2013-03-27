class Admin::PrizesController < Admin::ApplicationController
  def index
    render_json { auto_paginate(Prize.where(:is_deleted => false)) }
  end


  def_each :virtual, :cash, :entity, :lottery, :stockout, :expired do |method_name|
    @prizes = auto_paginate(Prize.send(method_name))
    render_json { @prizes }
  end

  def for_lottery
    render_json { Prize.for_lottery }
  end

  def create
    unless create_photo(:prize)
      render_json false do
        ErrorEnum::PHOTP_CANNOT_BE_BLANK
      end
    end
    @prize = Prize.new(params[:prize])
    # if params[:prize][:type] == 3
    #   l = Lottery.where(:_id => params[:prize][:lottery]).first
    #   if !l.nil?
    #     params[:prize][:lottery] = l
    #     @prize.lottery = l
    #     @prize.lottery.save
    #   else
    #     render_json(false){ErrorEnum::LOTTERY_NOT_FOUND}
    #   end
    # end
    render_json @prize.save do
      @prize.photo.save
      @prize.as_retval
    end
  end

  def update

    render_json false do
      Prize.find_by_id(params[:id]) do |prize|
        update_photo(:prize, prize)

        if prize.update_attributes(params[:prize])
          @is_success = true
        end
        prize.as_retval
      end
    end


    # if params[:prize][:type] == 3
    #   l = Lottery.where(:_id => params[:prize][:lottery]).first
    #   if !l.nil?
    #     params[:prize][:lottery] = l
    #     @prize.lottery = l
    #     @prize.lottery.save
    #   else
    #     render_json(false){ErrorEnum::LOTTERY_NOT_FOUND}
    #   end
    # end

  end

  def show
    # @prize = Prize.find_by_id(params[:id])
    # @prize[:photo_src] = @prize.photo.picture_url unless @prize.photo.nil?
    # @prize[:lottery_id] = @prize.lottery._id unless @prize.lottery.nil?
    # render_json { @prize }
    render_json false do
      result = Prize.find_by_id(params[:id]) do |prize|
        prize[:photo_src] = prize.photo.picture_url unless prize.photo.nil?
        prize[:lottery_id] = prize.lottery._id unless prize.lottery.nil?
        @is_success = true
        prize
      end
    end

  end

  def destroy
    @prize = Prize.find_by_id(params[:id])
    render_json @prize.is_valid? do |g|
      @prize.update_attribute('is_deleted', true) if g
    end
  end
end