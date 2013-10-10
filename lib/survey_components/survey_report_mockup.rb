module SurveyComponents::SurveyReportMockup
  extend ActiveSupport::Concern

  included do
    has_many :report_mockups
  end

  def create_report_mockup(report_mockup)
    result = ReportMockup.check_and_create_new(self, report_mockup)
    return result
  end

  def show_report_mockup(report_mockup_id)
    report_mockup = self.report_mockups.find_by_id(report_mockup_id)
    return ErrorEnum::REPORT_MOCKUP_NOT_EXIST if report_mockup.nil?
    return report_mockup
  end

  def list_report_mockups
    return self.report_mockups
  end

  def delete_report_mockup(report_mockup_id)
    report_mockup = self.report_mockups.find_by_id(report_mockup_id)
    if !report_mockup.nil?
      report_mockup.destroy
      return true
    else
      return ErrorEnum::REPORT_MOCKUP_NOT_EXIST
    end
  end

  def update_report_mockup(report_mockup_id, report_mockup_obj)
    report_mockup = self.report_mockups.find_by_id(report_mockup_id)
    return ErrorEnum::REPORT_MOCKUP_NOT_EXIST if report_mockup.nil?
    return report_mockup.update_report_mockup(report_mockup_obj)
  end
end