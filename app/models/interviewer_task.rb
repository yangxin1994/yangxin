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

  def self.create_interviewer_task(survey_id, user_id, quota)
    survey = Survey.find_by_id(survey_id)
    return ErrorEnum::SURVEY_NOT_EXIST if survey.nil?
    interviewer = User.find_by_id(user_id)
    return ErrorEnum::INTERVIEWER_NOT_EXIST if interviewer.nil?
    return ErrorEnum::INTERVIEWER_NOT_EXIST if !interviewer.is_interviewer?
    quota.merge!({"finished_count" => 0,
                "submitted_count" => 0,
                "rejected_count" => 0})
    quota["rules"] ||= []
    quota["rules"]=quota["rules"].map do |r|
        r["amount"] = r["amount"] || 0
        r["finished_count"] = 0
        r["submitted_count"] = 0
        r
    end
    interviewer_task = InterviewerTask.create(quota: quota, user: interviewer, survey: survey)
    # survey.interviewer_tasks << interviewer_task and survey.save
    # interviewer.interviewer_tasks << interviewer_task and interviewer.save
    return interviewer_task
  end


  # Just update status 
  # 
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
>>>>>>> df4200f65e5cbe61f0009179be75bd645975d385
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
        if answer.satisfy_conditions(rule["conditions"] || [], false)
          rule["finished_count"] += 1
          rule["submitted_count"] += 1
        end
      end
    end

    # make stats for the unreviewed answers
    unreviewed_answers.each do |answer|
      self.quota["submitted_count"] += 1
      self.quota["rules"].each do |rule|
        if answer.satisfy_conditions(rule["conditions"] || [], false)
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
end
