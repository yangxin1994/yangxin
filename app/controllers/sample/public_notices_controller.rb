class Sample::PublicNoticesController < Sample::SampleController

	before_filter :get_pclient

	def show
		@public_notice = @pclient.show(params[:id])
		@public_notice.success ? @public_notice = @public_notice.value : @public_notice = nil
	end

	def index
		@public_notices = @pclient.index(params[:page].to_i, 15)
		#@public_notices = @pclient.index(params[:page].to_i, 3)
		@public_notices.success ? @public_notices = @public_notices.value : @public_notices = nil
	end
	
	private
	def get_pclient
	  @pclient = Sample::PublicNoticeClient.new(session_info)
	end

end