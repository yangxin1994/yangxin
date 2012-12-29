class Admin::GiftsController < Admin::ApplicationController


  def index
    @gifts = params[:user_id].blank? ? Gift.all : Gift.where(:_id => params[:user_id]) 
    render_json true do |s|
      if s
        auto_paginate(@gifts) 
      else
        {
          error_code: ErrorEnum::USER_NOT_FOUND,
          error_message: "User not found"
        }
      end
    end
  end

  def_each :virtual, :cash, :entity, :lottery, :stockout, :expired do |method_name|
    @gifts = auto_paginate(Gift.send(method_name))
    render_json { @gifts }
  end

  def create
    unless create_photo(:gift)
      render_json false do
        ErrorEnum::PHOTP_CANNOT_BE_BLANK
      end   
    end 
    @gift = Gift.create(params[:gift])
    # if params[:gift][:type] == 3
    #   l = Lottery.where(:_id => params[:gift][:lottery]).first
    #   if !l.nil?
    #     params[:gift][:lottery] = l
    #     @gift.lottery = l
    #     @gift.lottery.save
    #   else
    #     render_json(false){ErrorEnum::LOTTERY_NOT_FOUND}
    #   end
    # end
    
    # @gift.photo = material
    # material.save
    # TODO add admin_id
    render_json @gift.save do
      @gift.as_retval
    end
  end

  def update
    @gift = Gift.find_by_id params[:id]
    unless params[:gift][:photo].nil?
      if @gift.photo.nil?
        material = Material.create(:material_type => 1, 
                                   :title => params[:gift][:name],
                                   :value => params[:gift][:photo],
                                   :picture_url => params[:gift][:photo])
        @gift.photo = material
      end
      @gift.photo.value = params[:gift][:photo]
      @gift.photo.picture_url = params[:gift][:photo]
      params[:gift][:photo] = material
      @gift.photo.save
    end

    
    if params[:gift][:type] == 3
      l = Lottery.where(:_id => params[:gift][:lottery]).first
      if !l.nil? 
        params[:gift].delete(:lottery)
        @gift.lottery = l
        @gift.lottery.save
      else
        render_json(false){ErrorEnum::LOTTERY_NOT_FOUND}
      end
    end
    params[:gift].select!{ |k, v| !v.nil?}
    render_json @gift.update_attributes(params[:gift]) do
      @gift.as_retval
    end
  end
  
  def show
    # @gift = Gift.find_by_id(params[:id])
    # @gift[:photo_src] = @gift.photo.picture_url unless @gift.photo.nil?
    # @gift[:lottery_id] = @gift.lottery._id unless @gift.lottery.nil?
    # render_json { @gift }
    render_json false do
      result = Gift.find_by_id(params[:id]) do |gift|
        gift[:photo_src] = gift.photo.picture_url unless gift.photo.nil?
        gift[:lottery_id] = gift.lottery_id
        @is_success = true
        gift
      end
    end
  end

  def destroy
    render_json false do |g|
      Gift.find_by_id(params[:id]) do |gift|
        @is_success = true if gift.update_attribute('is_deleted', true)
      end
    end
  end
end