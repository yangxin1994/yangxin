# finish migrating
class Quill::AuthoritiesController < Quill::QuillController
    
    before_filter :ensure_survey, :only => [:show, :update]

    # PAGE: show survey authority
    def show
        @authority = @survey.access_control_setting
    end

    # AJAX: update survey authority
    def update
        retval = @survey.update_access_control_setting(params[:authority])
        render_json_auto retval and return
    end
end