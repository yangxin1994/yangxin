class NetrankingUser
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :email, type: String, default: ""

end