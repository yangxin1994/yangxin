# encoding: utf-8
class Vote::SuffragesController < Vote::VoteController

  def index
    new_vote
    @playing_movies = Movie.get_playing(cookies[:vote_user_id])
    @later_movies   = Movie.get_later(cookies[:vote_user_id])
  end

  def statrt_vote
    if cookies[:vote_user_id].present?
      current_vote_user = VoteUser.where(id:cookies[:carnival_user_id]).first
    else
      current_vote_user = VoteUser.create_new(current_user.id.to_s)
      set_vote_user_cookie(@current_vote_user.id.to_s)
    end

    suffrage = Suffrage.create_new(current_vote_user.id.to_s,movie_id,vt)

    render_json_auto suffrage and return 
  end


  private
  def new_vote
    unless cookies[:vote_user_id].present? 
      @current_vote_user = VoteUser.create_new(current_user.try(:id).to_s) 
      set_vote_user_cookie(@current_vote_user.id.to_s)      
    end
  end  

end