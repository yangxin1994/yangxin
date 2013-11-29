class OfflineUser
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :email, type: String, default: ""
  field :mobile, type: String
  field :name, type: String
  field :invited, type: Boolean, default: false
  field :survey_title, type: String, default: ""
  field :participate_at, type: Integer

  def self.import
    content = File.read('lib/offline_users')
    
  end
end