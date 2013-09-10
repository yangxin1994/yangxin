# finish migrating
class Sample::PublicNoticesController < Sample::SampleController

	def index
		params[:per_page] = 15
		@public_notices = auto_paginate PublicNotice.opend.desc(:updated_at)
	end

	def show
		@public_notice = PublicNotice.find_by_id(params[:id])
		pids = PublicNotice.where(:status => 2).desc(:updated_at)
		if pids.present?
			tmp_hash = {}
			pids.each_with_index do |pid,index|
				tmp_hash["#{pid['_id']}"] = index
			end
		end
		tmp_hash['current_notice'] = @public_notice
		@public_notice = tmp_hash
	end


	
end