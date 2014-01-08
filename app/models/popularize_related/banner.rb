# encoding: utf-8
class Banner
  
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  OPENED = 2
  DELETED = 4

  field :title, :type => String, default: "调查问卷主标题"
  field :subtitle, :type => String, default: ""
  field :welcome, :type => String, default: ""
  field :closing, :type => String, default: "调查问卷结束语"
  field :header, :type => String, default: ""
  field :footer, :type => String, default: ""
  field :description, :type => String, default: "调查问卷描述"

  belongs_to :user, class_name: "User", inverse_of: :surveys

  scope :opened, -> { where(:status => 2) }
  scope :deleted, -> { where(:status => 4) }

  public

  
end
