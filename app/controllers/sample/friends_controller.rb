class Sample::FriendsController < Sample::SampleController

	before_filter :require_sign_in

	def initialize
		super('friend')
	end

	def index
		result = Account::UserClient.new(session_info).get_introduced_users(params[:page].to_i, 20)
		@friends = (result.success ? result.value : nil)
		logger.debug @friends.inspect
	end

end