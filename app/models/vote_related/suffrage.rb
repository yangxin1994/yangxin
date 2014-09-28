# encoding: utf-8
class Suffrage
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  VOTE_TYPE_0 = 0 #想看
  VOTE_TYPE_1 = 1 #不想看
  VOTE_TYPE_2 = 2 #看过

  field :vote_type, type:Integer # 表示是想看、不想看、看过
  field :user_id, type: String
  field :movie_id,type: String

  def self.create_new(user_id,movie_id,vt)
  	suffrage =  self.where(user:user_id,movie_id:movie_id).first
  	if suffrage.present?
  		self.update(vote_type:vt)
  	else
  		suffrage = self.create(user_id:user_id,movie_id:movie_id,vote_type:vt)	
  	end
  	result  = self.where(movie_id:movie_id)
  	want    = result.where(vote_tpye:VOTE_TYPE_0).count
  	no_want = result.where(vote_tpye:VOTE_TYPE_1).count
  	seen    = result.where(vote_tpye:VOTE_TYPE_2).count
  	return  {total:result.count,want:want,no_want:no_want,seen:seen}  
  end
end
