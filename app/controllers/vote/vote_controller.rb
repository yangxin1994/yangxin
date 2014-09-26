class Vote::VoteController < ApplicationController
  layout false

  def set_vote_user_cookie(id)
    cookies[:vote_user_id] = {
      :value => id,
      :expires => 12.months.from_now,
      :domain => :all
    }
  end

end
