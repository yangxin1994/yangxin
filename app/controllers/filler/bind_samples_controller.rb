# finish migrating
class Filler::BindSamplesController < Filler::FillerController
  before_filter :require_sign_in

  def show
    bind_ids = (cookies[Rails.application.config.bind_answer_id_cookie_key] || '').split('_')
    redirect_aid = nil
    bind_ids.each do |aid|
      a = Answer.find_by_id(aid)
      next if a.nil? || a.user.present?
      a.bind_sample(current_user)
      redirect_aid = aid 
      # delete filler id
      cookies.delete("#{a['survey_id']}_0", :domain => :all) if cookies["#{a['survey_id']}_0"] == aid
      # delete preview id
      cookies.delete("#{a['survey_id']}_1", :domain => :all) if cookies["#{a['survey_id']}_1"] == aid
    end
    # delete answer ids in cookie
    cookies.delete(Rails.application.config.bind_answer_id_cookie_key, :domain => :all)
    redirect_to params[:ref] and return if params[:ref].present?
    redirect_to show_a_path(redirect_aid) and return if redirect_aid.present?
    redirect_to root_path and return
  end
end