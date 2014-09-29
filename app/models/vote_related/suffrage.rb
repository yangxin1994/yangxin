# encoding: utf-8
class Suffrage
  include Mongoid::Document
  include Mongoid::Timestamps

  VOTE_TYPE_0 = 0 #想看
  VOTE_TYPE_1 = 1 #不想看
  VOTE_TYPE_2 = 2 #看过

  field :vote_type, type:Integer # 表示是想看、不想看、看过
  field :user_id, type: String
  # field :movie_id,type: String
  belongs_to :movie
  belongs_to :vote_user
  scope :want,-> {where(vote_type:VOTE_TYPE_0)}
  scope :no_want,-> {where(vote_type:VOTE_TYPE_1)}
  scope :seen,-> {where(vote_type:VOTE_TYPE_2)}
  def self.create_new(user_id,movie_id,vt)
  	suffrage =  self.where(user_id:user_id,movie_id:movie_id).first
  	if suffrage.present?
  		suffrage.update(vote_type:vt)
  	else
  		suffrage = self.create(user_id:user_id,movie_id:movie_id,vote_type:vt)	
  	end
  	result  = self.where(movie_id:movie_id)
  	want    = result.want.count
    no_want = result.no_want.count
    seen    = result.seen.count    
  	return  {total:result.count,want:want,no_want:no_want,seen:seen}  
  end
end
