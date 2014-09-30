# encoding: utf-8
class VoteUser

  include Mongoid::Document
  include Mongoid::Timestamps

  # field :user_id, type: String
  has_many :suffrages
  def self.create_new(user_id=nil)
    vote_user = self.create(user_id:user_id)
    return vote_user
  end
end
