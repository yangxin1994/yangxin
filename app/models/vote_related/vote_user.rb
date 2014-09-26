# encoding: utf-8
class VoteUser

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :user_id, type: String

  def self.create_new(user_id=nil)
    vote_user = self.create(user_id:user_id)
    return vote_user
  end
end
