class Carnival::CampaignsController < Carnival::CarnivalController
  def index

    c_user = User.new unless cookie[:current_user_id].present?
    @current_user_id = cookie[:current_user_id] || c_user.id

    @prev_survey = Survey.last
    @prev_answer = @prev_survey.answers.where(:user_id => @current_user_id) 
    
    # set cookie ticket true or false
    # set cookie current_step 0 1 2 3
     

  end
end