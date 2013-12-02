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
    content = File.read("lib/data")
    user_ary = content.split("\n")
    user_ary.each do |u|
      data = u.split("\t")
      OfflineUser.create(name: data[0], email: data[1], survey_title: data[2])
    end
  end
end