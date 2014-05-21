# encoding: utf-8
class Admin::PreSurveysController < Admin::AdminController

  layout "layouts/admin-todc"

	# *****************************

  def index
    render text: "presurvey#index, survey id: #{params[:survey_id]}"
  end
end
