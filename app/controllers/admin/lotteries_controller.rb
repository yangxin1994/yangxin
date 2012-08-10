# encoding: utf-8
class Admin::LotteriesController < Admin::ApplicationController
	
	def index
		@lotteries = Lottery.page(page)
		@lotteries = ErrorEnum::LotteryNotFound if @lotteries.empty?
		respond_to do |format|
			format.html
			format.json { render json: @lotteries}
		end
	end

	def create
		respond_to do |format|
			@lottery = Lottery.create(params[:lottery])
			# TO DO add admin_id
			if @lottery.save
				Material.create(:material => params[:material], :materials => @lottery)
				format.html { redirect_to :action => 'show',:id => @lottery.id }
				format.json { render json: @lottery, status: :created, location: @lottery }
			else
				format.json { render json: false }
			end
		end
	end

	def draw
		@result = LotteryCode.find_by_id params[:id] do |r|
				r.draw
			end
		respond_to do |format|
				format.json {render json: @result }
		end
	end

end
