class Admin::LotteriesController < Admin::ApplicationController
	
	def index
		render_json { auto_paginate(Lottery.all)}
	end

  def create
    create_photo(:lottery)
    @lottery = Lottery.new(params[:lottery])
    add_prizes(get_prize_ids, @lottery)
    render_json @lottery.save do
      @lottery.photo.save
      @lottery.as_retval
    end
  end

  def update
    render_json false do
      Lottery.find_by_id(params[:id]) do |lottery|
        update_photo(:lottery, lottery)
        add_prizes(get_prize_ids, lottery)
        if lottery.update_attributes(params[:lottery])
          @is_success = true
        end
        lottery.as_retval
      end
    end
    
  end

	# def create
 #    material = Material.create(:material_type => 1, 
 #                               :title => params[:lottery][:title],
 #                               :value => params[:lottery][:photo],
 #                               :picture_url => params[:lottery][:photo])
 #    # logger.info "=========#{params[:lottery][:photo]}========="
 #    params[:lottery][:photo] = material

 #    lp_ids = params[:lottery][:prize_ids]
 #    params[:lottery][:prize_ids] = nil
	# 	@lottery = Lottery.new(params[:lottery])
 #    lp_ids.each do |i|
 #      lp = Prize.where("_id"=> i).first
 #      @lottery.prizes << lp #unless lp.nil?
 #      lp.save
 #    end unless lp_ids.nil?
 #    @lottery.photo = material
 #    material.save
 #    render_json @lottery.save do
	# 			#Material.create(:material => params[:material], :materials => @lottery)
	#     @lottery.as_retval
	# 	end
	# 		# TODO add admin_id
	# end

  # def update
  #   @lottery = Lottery.find_by_id params[:id]
  #   unless params[:lottery][:photo].nil?
  #     if @lottery.photo.nil?
  #       material = Material.create(:material_type => 1, 
  #                                  :title => params[:lottery][:name],
  #                                  :value => params[:lottery][:photo],
  #                                  :picture_url => params[:lottery][:photo])
        
  #       @lottery.photo = material
  #     end
  #     @lottery.photo.value = params[:lottery][:photo]
  #     @lottery.photo.picture_url = params[:lottery][:photo]
  #     params[:lottery][:photo] = material
  #     @lottery.photo.save
  #   end
  #   # 增加奖品
  #   lp_ids = params[:lottery][:prize_ids]
  #   @lottery.prizes if lp_ids
  #   params[:lottery][:prize_ids] = nil
  #   #@lottery = Lottery.new(params[:lottery])
  #   lp_ids.each do |i|
  #     Prize.find_by_id(i) do |prize|
  #       @lottery.prizes << prize 
  #     end

  #     # lp = Prize.where("_id"=> i).first
  #     # @lottery.prizes << lp #unless lp.nil?
  #     # lp.save
  #   end unless lp_ids.nil?
  #   # @lottery = Lottery.find_by_id params[:id]
  #   render_json @lottery.update_attributes(params[:lottery]) do
  #     @lottery.as_retval
  #   end
  # end
  
  def_each :for_publish, :activity, :finished do |method_name|
    @lottery = auto_paginate(Lottery.send(method_name))
    render_json { @lottery }
  end

  def show
    render_json false do
      Lottery.find_by_id(params[:id]) do |l|
        l[:prizes] = l.prizes
        l[:prize_ids] = l.prizes.map(&:_id)
        l[:photo_src] = l.photo.picture_url unless l.photo.nil?
        @is_success = true
        #binding.pry
        l
      end
    end
  end

  def auto_draw
    render_json false do
      Lottery.find_by_id(params[:id]) do |l|
        # binding.pry
        @is_success = true
        l.auto_draw
      end
    end
  end
  
  def assign_prize
    render_json false do
      Lottery.find_by_id(params[:id]) do |lottery|
        lottery.prizes.find_by_id(params[:prize_id]) do |prize|
          user = User.find_by_id(params[:user_id])
          unless user.nil?
            @is_success = true
            lottery.assign_prize(user, prize)
          end
        end
      end
    end
  end

  def prize_records
    render_json false do
      Lottery.find_by_id(params[:id]) do |lottery|
        success_true
        auto_paginate lottery.lottery_codes.drawed_w_n do |lottery_codes|
          lottery_codes.map do |lottery_code|
            lottery_code[:prize] = lottery_code.prize
            lottery_code[:user] = lottery_code.user
            lottery_code
          end
        end
      end
    end
  end

  def lottery_codes
    render_json false do
      Lottery.find_by_id(params[:id]) do |lottery|
        success_true
        auto_paginate lottery.lottery_codes.all do |lottery_codes|
          lottery_codes.map do |lottery_code|
            lottery_code[:user] = lottery_code.user
            lottery_code            
          end
        end
      end
    end
  end

  def ctrl
    render_json false do
      Lottery.find_by_id(params[:id]) do |lottery|
        success_true
        lottery[:prizes] = lottery.prizes
        ch = []
        # 优化!!!
        lottery.prizes.each do |prize|
          if params[:only_active]
            ch += prize.active_ctrl_history
          else
            ch += prize.ctrl_history
          end
        end
        lottery[:ctrl_history] = ch
        lottery
      end
    end
  end

  def add_ctrl_rule
    render_json false do
      Prize.find_by_id(params[:id]) do |prize|
        success_true
        prize.add_ctrl_rule(params[:ctrl_surplus], params[:ctrl_time], params[:weight])
      end
    end
  end

  def destroy
    render_json do
      Lottery.find_by_id(params[:id]) do |e|
        e.update_attribute("is_deleted", true)
      end
    end 
  end
  # private
  def get_prize_ids
    params[:lottery][:prize_ids].split ',' unless params[:lottery][:prize_ids].nil?
  end

  def add_prizes(prize_ids, lottery)
    return unless prize_ids
    prize_ids.each do |id|    
      Prize.find_by_id(id) do |prize|
        params[:lottery].delete(:prize_ids)
        prize.lottery = lottery #unless prize.lottery
        binding.pry
        lottery.save
        prize.save
        binding.pry
      end
    end
  end

end
