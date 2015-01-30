require 'error_enum'
require 'quill_common'
class InterviewerTask
  
  include Mongoid::Document 
  include Mongoid::Timestamps
  include FindTool
  
  field :quota, :type => Hash
  # 0(doing), 1(under review), 2(finished)
  field :status, :type => Integer, default: 0

  belongs_to :survey
  belongs_to :user
  has_many :answers

  def self.create_interviewer_task(survey_id, user_id, amount)
    survey = Survey.find(survey_id)
    interviewer = User.find(user_id)
    return ErrorEnum::INTERVIEWER_NOT_EXIST if !interviewer.is_interviewer?
    quota = {"rules" => [{
        "amount" => amount,
        "finished_count" => 0,
        "submitted_count" => 0}],
      "finished_count" => 0,
      "submitted_count" => 0,
      "rejected_count" => 0}
    InterviewerTask.create(quota: quota, user: interviewer, survey: survey)
  end

  def update_amount(amount)
    self.quota["rules"][0]["amount"] = amount
    self.update_status
  end

  # Just update status 
  def update_status
    # calculate whether quota is satisfied
    finished = true
    under_review = true
    self.quota["rules"].to_a.each do |rule|
        finished = false if rule["finished_count"].to_i < rule["amount"].to_i
        under_review = false if rule["submitted_count"].to_i < rule["amount"].to_i
    end
    if finished
        self.status = 2
    elsif under_review
        self.status = 1
    else
        self.status = 0
    end
    self.save
  end


  # update quota based answers 
  # 
  def refresh_quota
    self.quota["finished_count"] = 0
    self.quota["submitted_count"] = 0
    self.quota["rejected_count"] = 0
    self.quota["rules"].each do |r|
        r["finished_count"] = 0
        r["submitted_count"] = 0
    end
    finished_answers = self.answers.not_preview.finished
    unreviewed_answers = self.answers.not_preview.unreviewed
    rejected_answers = self.answers.not_preview.rejected
    # make stats for the finished answers
    finished_answers.each do |answer|
        self.quota["finished_count"] += 1
        self.quota["submitted_count"] += 1
        self.quota["rules"].each do |rule|
            if answer.satisfy_conditions(rule["conditions"] || [])
                rule["finished_count"] += 1
                rule["submitted_count"] += 1
            end
        end
    end
    # make stats for the unreviewed answers
    unreviewed_answers.each do |answer|
        self.quota["submitted_count"] += 1
        self.quota["rules"].each do |rule|
            if answer.satisfy_conditions(rule["conditions"] || [])
                rule["submitted_count"] += 1
            end
        end
    end

    # make stats for the rejected answers
    self.quota["rejected_count"] = rejected_answers.length

    # update status
    self.update_status

    return self
  end

  def submit_answers(answers)
    Rails.logger.info "111&&&&&&&&&&&&&&&&&&&&"
    Rails.logger.info answers.inspect
    answers.each do |a|
      # convert the gps or 3g location to a region code
      Rails.logger.info "2&&&&&&&&&&&&&&&&&&&&"
      region = -1
      begin
        Rails.logger.info "2.1&&&&&&&&&&&&&&&&&&&&"
        # region = QuillCommon::AddressUtility.find_region_code_by_latlng(*a["location"])
        Rails.logger.info "2.2&&&&&&&&&&&&&&&&&&&&"
      rescue
        region = -1
      end
      Rails.logger.info "3&&&&&&&&&&&&&&&&&&&&"
      if a["status"].to_i == 1
        status = Answer::REJECT
      else
        # status = self.survey.answer_need_review ? Answer::UNDER_REVIEW : Answer::FINISH
        status = Answer::UNDER_REVIEW
      end
      Rails.logger.info "4&&&&&&&&&&&&&&&&&&&&"
      answer_to_insert = {:interviewer_task_id => self._id,
        :survey_id => self.survey_id,
        :channel => -2,
        :created_at => Time.at(a["created_at"]),
        :finished_at => a["finished_at"].to_i,
        :answer_content => a["answer_content"],
        :attachments => a["attachments"],
        :latitude => a["location"][0].to_s,
        :longitude => a["location"][1].to_s,
        :status => status,
        :reject_type => a["reject_type"].to_i,
        :region => region}
      Rails.logger.info "4&&&&&&&&&&&&&&&&&&&&"
      Rails.logger.info answer_to_insert.inspect
      retval = Answer.create(answer_to_insert)
      Rails.logger.info "&&&&&&&&&&&&&&&&&&&&"
      Rails.logger.info retval.inspect
      Rails.logger.info "&&&&&&&&&&&&&&&&&&&&"
    end
    self.refresh_quota
    return self
  end

  def info_for_admin
    self.write_attribute(:amount, self.quota["rules"][0]["amount"])
    self.write_attribute(:finished_count, self.quota["finished_count"])
    self.write_attribute(:submitted_count, self.quota["submitted_count"])
    self.write_attribute(:rejected_count, self.quota["rejected_count"])
    self.write_attribute(:interviewer, self.user.nickname)
    return self
  end

	def info_for_interviewer
		self.quota["amount"] = self.quota["rules"][0]["amount"]
    self.write_attribute(:create_time, self.created_at.to_i)
    self.write_attribute(:update_time, self.survey.last_update_time)
		return self
	end
end
