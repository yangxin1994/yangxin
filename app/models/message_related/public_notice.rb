#already tidied up
class PublicNotice
  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  field :title, :type => String
  field :content, :type => String
  field :attachment, :type => String
  ## status can be 1(close)，2(publish) 4(deleted, just can be change by destroy method)
  field :status, :type => Integer, :default => 2

  belongs_to :user

  # index({ title: 1, public_notice_type: 1 }, { background: true } )
  # index({ public_notice_type: 1, content: 1 }, { background: true } )
  
  # attr_accessible :title, :content, :attachment, :status#, :public_notice_type

  scope :opend, where(:status => 2)
  scope :closed, where(:status => 1)

  index({ status: 1 }, { background: true } )
  index({ title: 1 }, { background: true } )

  validates_presence_of :title#, :public_notice_type
    
  class << self

    # def find_by_id(public_notice_id)
    #   public_notice = PublicNotice.where(_id: public_notice_id.to_s).first
    #   return public_notice
    # end

    def find_valid_notice
      PublicNotice.in(status: [1, 2]).desc(:updated_at)
    end

    def find_by_title(title)
      title.blank? ? self : self.where(:title => /.*#{title}.*/)
    end

    def create_public_notice(new_public_notice, user)
      public_notice = PublicNotice.new(new_public_notice)
      user.public_notices << public_notice if user && user.instance_of?(User)
      public_notice.save
      return public_notice     
    end
  end 
end