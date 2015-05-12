class Filler::SurveysController < Filler::FillerController

    # PAGE
    def show
        load_survey(params[:id])
    end

    def wechart_auth
    	Rails.logger.info '================================'
    	Rails.logger.info params.inspect
    	Rails.logger.info '================================'
    end
end