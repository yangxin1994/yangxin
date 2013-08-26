# finish migrating
class Sample::PrizesController < Sample::SampleController

	def initialize
		super('prizes')
	end

	def find_by_ids
		@prizes = Prize.where(:_id.in => params[:ids].split(','))
		@prizes = @prizes.map do |prize|
			prize['photo_src'] = prize.photo.present? ? prize.photo.picture_url : Prize::DEFAULT_IMG
			prize
		end
		render_json_auto(@prizes)
		# params[:ids] should be an array with elements like ['xxx','yyy','zzz']
    	# render :json => Sample::PrizeClient.new(session_info).show(params[:ids])
	end
end