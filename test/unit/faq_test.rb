require 'test_helper'

class FaqTest < ActiveSupport::TestCase

	test "01 find_by_type" do
		
		clear(Faq)
		
		assert_raise(TypeError) { 
			Faq.create(faq_type: "type1", question: "question0", answer: "answer0") 
		}
		
		assert_raise(RangeError) { 
			Faq.create(faq_type: 0, question: "question0", answer: "answer0") 
		}
		
		assert_raise(RangeError) { 
			Faq.create(faq_type: 3, question: "question0", answer: "answer0") 
		}
		
		assert_raise(RangeError) { 
			Faq.create(faq_type: 129, question: "question0", answer: "answer0") 
		}
		
		Faq.create(faq_type: 1, question: "question1", answer: "answer1")
		Faq.create(faq_type: 2, question: "q2", answer: "answer2")
		
		assert_equal Faq.find_by_type(0, "question").count, 1
		assert_equal Faq.find_by_type(0, "answer").count, 2
		assert_equal Faq.find_by_type(1, "answer").count, 1
		assert_equal Faq.find_by_type(3, "answer").count, 2
		
		clear(Faq)
		
	end
	
end
