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

	def new
		@lottery = Lottery.new
		respond_to do |format|
			format.html
		end
	end

	def create
		respond_to do |format|
			@lottery = Present.create(params[:lottery])
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
end
