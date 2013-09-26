# coding: utf-8
#already tidied up
class Feedback
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :feedback_type, :type => Integer
  field :title, :type => String
  field :content, :type => String
  field :is_answer, :type => Boolean, :default => false
  # add attr to store reply message
  field :reply_message, :type => String
  
  attr_accessible :feedback_type, :title, :content

  validates_presence_of :feedback_type, :title, :content
  
  belongs_to :question_user, class_name: "User", inverse_of: :question_feedback
  belongs_to :answer_user, class_name: "User", inverse_of: :answer_feedback

  scope :answered, where(is_answer: true)
  scope :unanswer, where(is_answer: false)
  
  # the max of multiple type value => 2**7
  MAX_TYPE = 7
  
  #--
  # instance methods
  #++

  
  #--
  # class methods
  #++
  
  index({ feedback_type: 1, title: 1, is_answer: 1 }, { background: true } )
  index({ title: 1, is_answer: 1 }, { background: true } )
  index({ is_answer: 1 }, { background: true } )
  index({ feedback_type: 1, is_answer: 1 }, { background: true } )
  index({ question_user_id: 1, feedback_type: 1, title: 1, is_answer: 1 }, { background: true } )
  index({ question_user_id: 1, title: 1, is_answer: 1 }, { background: true } )
  index({ question_user_id: 1, is_answer: 1 }, { background: true } )
  index({ question_user_id: 1, feedback_type: 1, is_answer: 1 }, { background: true } )

  class << self

    def find_by_id(feedback_id)
      feedback = Feedback.where(_id: feedback_id.to_s).first
      return ErrorEnum::FEEDBACK_NOT_EXIST if feedback.nil?
      return feedback
    end     
  end 
  
end
