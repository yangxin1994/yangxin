class Admin::ApplicationController < ApplicationController
#layout 'admin'
# before_filter :require_admin
 #  def require_admin
 #    if not Setting.admin_emails.include?(current_user.email)
 #      render_404
 #    end
 #  end
end