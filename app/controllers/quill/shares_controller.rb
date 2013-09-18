# finish migrating
class Quill::SharesController < Quill::QuillController

    before_filter :ensure_survey, :only => [:show]

    def initialize
        super(3)
    end

    # PAGE: show survey share
    def show
        @hide_left_sidebar = true
        @survey_questions = get_survey_questions
        @survey_quota = @survey.quota
        reward_scheme_id = @survey.reward_schemes.where(:default => true).first.try(:_id)
        if reward_scheme_id.present?
            # @short_url = "#{Rails.application.config.quillme_host}#{show_s_path(reward_scheme_id)}"
            @short_url = "#{request.protocol}#{request.host_with_port}#{show_s_path(reward_scheme_id)}"
            result = MongoidShortener.generate(@short_url)
            if result.present?
                # @short_url = "#{Rails.application.config.quillme_host}/#{result}"
                @short_url = "#{request.protocol}#{request.host_with_port}/#{result}"
            end
        end
    end
end