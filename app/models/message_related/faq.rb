class Faq
  include Mongoid::Document 
  include Mongoid::Timestamps

  #faq_type max number
  MAX_TYPE = 7

  # faq_type divide from 1, 2, 4, 8, ...,
  field :faq_type, :type => Integer
  field :question, :type => String
  field :answer, :type => String
          
  belongs_to :user

  attr_accessible :faq_type, :question, :answer

  validates_presence_of :faq_type, :question, :answer

  index({ faq_type: 1, question: 1 }, { background: true } )
  index({ faq_type: 1, answer: 1 }, { background: true } )
  
  class << self   

    def find_by_id(faq_id)
      faq = Faq.where(_id: faq_id.to_s).first
      return ErrorEnum::FAQ_NOT_EXIST if faq.nil?
      return faq
    end

  end

end
