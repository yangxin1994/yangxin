class Utility::ShortUrlsController < ApplicationController

    def show
        result = ::ShortUrlClient.new(session_info, params[:unique_key]).show
        if result.success && !result.value.blank?
            redirect_to result.value and return
        else
            render_404
        end
    end

end