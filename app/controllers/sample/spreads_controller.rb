class Sample::SpreadsController < Sample::SampleController

	before_filter :require_sign_in, :only => [:show]

	def initialize
		super('survey')
	end

	def index
		client = Sample::SurveyClient.new(session_info)

		@spread_surveys = client.survey_list(params[:s].to_i, 5, -1, true)
		@spread_surveys.success ? @spread_surveys = @spread_surveys.value : @spread_surveys = nil

		@my_spread_surveys = client.my_spread_list(params[:m].to_i, 10)
		@my_spread_surveys.success ? @my_spread_surveys = @my_spread_surveys.value : @my_spread_surveys = nil
	end

end