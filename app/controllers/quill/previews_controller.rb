# finish migrating
class Quill::PreviewsController < Quill::QuillController
    before_filter :ensure_survey

    # PAGE: redirect to real preview page
    def show
        reward_scheme_id = @survey.reward_schemes.where(:default => true).first.try(:_id)
        redirect_to show_p_path(reward_scheme_id.present? ? reward_scheme_id : nil)
    end
end