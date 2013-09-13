module SurveyComponents::SurveyPage
  extend ActiveSupport::Concern

  included do
    field :pages, :type => Array, default: [{"name" => "", "questions" => []}]
  end

  def create_page(page_index, page_name)
    return ErrorEnum::OVERFLOW if page_index < -1 or page_index > self.pages.length - 1
    new_page = {"name" => page_name, "questions" => []}
    self.pages.insert(page_index+1, new_page)
    self.save
    return new_page
  end

  def split_page(page_index, question_id, page_name_1, page_name_2)
    current_page = self.pages[page_index]
    return ErrorEnum::OVERFLOW if current_page.nil?
    if question_id.to_s == "-1"
      question_index = current_page["questions"].length
    else
      question_index = -1
      current_page["questions"].each_with_index do |q_id, q_index|
        if q_id == question_id
          question_index = q_index
          break
        end
      end
      return ErrorEnum::QUESTION_NOT_EXIST if question_index == -1
    end
    if question_index == 0
      new_page_1 = {"name" => page_name_1, "questions" => []}
    else
      new_page_1 = {"name" => page_name_1,
            "questions" => current_page["questions"][0..question_index-1]}
    end
    new_page_2 = {"name" => page_name_2,
            "questions" => current_page["questions"][question_index..current_page["questions"].length-1]}
    self.pages.delete_at(page_index)
    self.pages.insert(page_index, new_page_2)
    self.pages.insert(page_index, new_page_1)
    self.save
    return [new_page_1, new_page_2]
  end

  def show_page(page_index)
    current_page = self.pages[page_index]
    return ErrorEnum::OVERFLOW if current_page.nil?
    page_object = {name: current_page["name"], questions: []}
    current_page["questions"].each do |question_id|
      temp = Question.get_question_object(question_id)
      temp["index"] = self.all_questions_id.index(question_id)
      page_object[:questions] << temp
    end
    return page_object
  end

  def combine_pages(page_index_1, page_index_2)
    return ErrorEnum::OVERFLOW if page_index_1 < 0 or page_index_1 > self.pages.length - 1
    return ErrorEnum::OVERFLOW if page_index_2 < 0 or page_index_2 > self.pages.length - 1
    self.pages[page_index_1+1..page_index_2].each do |page|
      self.pages[page_index_1]["questions"] = self.pages[page_index_1]["questions"] + page["questions"]
    end
    (page_index_2 - page_index_1).times do
      self.pages.delete_at(page_index_1+1)
    end
    return self.save
  end

  def move_page(page_index_1, page_index_2)
    current_page = self.pages[page_index_1]
    return ErrorEnum::OVERFLOW if current_page == nil
    return ErrorEnum::OVERFLOW if page_index_2 < -1 or page_index_2 > self.pages.length - 1
    self.pages.insert(page_index_2+1, current_page)
    self.pages.delete_at(page_index_1)
    return self.save
  end
end