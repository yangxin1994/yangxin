class Carnival::CarnivalController < ApplicationController
  layout 'carnival'

  def set_carnival_user_cookie(id)
    cookies[:carnival_user_id] = {
      :value => id,
      :expires => 12.months.from_now,
      :domain => :all
    }
  end

end
