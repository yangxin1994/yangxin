# finish migrating
class Sample::PublicNoticesController < Sample::SampleController

	# before_filter :get_pclient

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
		render_json { tmp_hash }


		@public_notice = @pclient.show(params[:id])
		@public_notice.success ? @public_notice = @public_notice.value : @public_notice = nil
	end

	def index
		params[:per_page] = 15
		@public_notices = auto_paginate PublicNotice.opend.desc(:updated_at)

		# @public_notices = @pclient.index(params[:page].to_i, 15)
		# @public_notices.success ? @public_notices = @public_notices.value : @public_notices = nil
	end
	
=begin
	private
	def get_pclient
	  @pclient = Sample::PublicNoticeClient.new(session_info)
	end
=end
end