class Sample::PrizesController < Sample::SampleController

	def initialize
		super('prizes')
	end

	def find_by_ids
	  # params[:ids] should be an array with elements like ['xxx','yyy','zzz']
	  prizes = Sample::PrizeClient.new(session_info).show(params[:ids])
      render :json => Sample::PrizeClient.new(session_info).show(params[:ids])
	end


end