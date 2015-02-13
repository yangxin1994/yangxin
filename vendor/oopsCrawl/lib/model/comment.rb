class Comment

  # include Mongoid::Document
  # #Nlpir::Mongoid.included(self)
  

  # field :user_name, :type => String
  # field :content, :type => String
  # field :votes, :type => Integer
  # field :rating, :type => Integer
  # field :created_at, :type => Integer

  # scope :include_word, ->(_k){ where(:content => /#{_k}/)}

  # validates :created_at, presence: true

  # belongs_to :movie

  # def self.group_by_create
  #   self.desc(:created_at).group_by{|bn| bn.created_at}
  # end

  # def self.get_by_create_day
  #   _data = []
  #   group_by_create.each do |_k, _v|
  #     _data << [Time.at(_k || 0).strftime('%F'), _v.count]
  #   end
  #   _data
  # end

  # def self.woms(keyword = '')
  #   if keyword.present?
  #     _comments = where(:content => /#{keyword}/) 
  #   else
  #     _comments = self
  #   end
  #   {
  #     :positive => _comments.where(:rating_ua.gt => 0).count,
  #     :negative => _comments.where(:rating_ua.lt => 0).count,
  #     :neuter => _comments.where(:rating_ua => 0).count
  #   }
  # end

end