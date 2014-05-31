require 'error_enum'
require 'securerandom'
class Carnival
  include Mongoid::Document


  field :quota, type: Hash, default: {amount: 0,
    gender: [0, 0],
    age: [0, 0, 0, 0, 0, 0, 0],
    income: [0, 0, 0, 0, 0, 0],
    education: [0, 0, 0, 0, 0],
    region: {"4096" => 0, # beijing
      "36864" => 0,       # shanghai
      "77888" => 0,       # guangzhou
      "78016" => 0,       # shenzhen
      "8192" => 0,        # tianjin
      "41024" => 0,       # nanjing
      "69696" => 0,       # wuhan
      "24640" => 0,       # shenyang
      "110656" => 0,       # xi'an
      "94272" => 0,       # chengdu
      "90112" => 0,       # chongqing
      "45120" => 0,       # hangzhou
      "61568" => 0,       # tsingdao
      "24704" => 0,       # dalian
      "45184" => 0,       # ningbo
      "61504" => 0,       # jinan
      "32832" => 0,       # harbin
      "28736" => 0,       # changchun
      "53376" => 0,       # xiamen
      "65600" => 0,       # zhengzhou
      "41280" => 0,       # suzhou
      "41088" => 0,       # wuxi
      "73792" => 0,       # changsha
      "53312" => 0,       # fuzhou
      "114752" => 0,      # lanzhou
      "127040" => 0,      # urumchi
      "102464" => 0,      # kunming
      "1" => 0,           # others-huadong
      "2" => 0,           # others-huanan
      "3" => 0,           # others-huazhong
      "4" => 0,           # others-huabei
      "5" => 0,           # others-xibei
      "6" => 0,           # others-xinan
      "7" => 0,           # others-dongbei
      }}
  field :survey_id, type: String
  SETTING = 1
  STATS = 2
  field :type, type: Integer


  PRE_SURVEY = "53859185eb0e5b7282000002"
  PRE_SURVEY_REWARD_SCHEME = "53859185eb0e5b7282000003"
  BACKGROUND_SURVEY = "53858ff3eb0e5b3366000023"
  BACKGROUND_SURVEY_REWARD_SCHEME = "53858ff3eb0e5b3366000024"
  SURVEY = ["53868990eb0e5ba257000025",
    "53843373eb0e5bac1d00002f",
    "538415caeb0e5b815400000b",
    "53843581eb0e5bff58000001",
    "538436c9eb0e5bf8cf00003d",
    "53859a0deb0e5b2452000021",
    "53881af6eb0e5bb25600001d",
    "5388279feb0e5b9d630000e2",
    "5384011beb0e5b091d00001a",
    "5384282deb0e5bbcb900002b",
    "53842c9aeb0e5bbcb90000a1",
    "53842d30eb0e5bb228000008",
    "5385982aeb0e5b7282000022",
    "53843187eb0e5b2ac8000037"]

  ALL_SURVEY = SURVEY + [PRE_SURVEY, BACKGROUND_SURVEY]

  def self.generate_data
    return if Carnival.all.length > 0
    SURVEY.each do |e|
      Carnival.create(survey_id: e, type: STATS)
    end
    Carnival.create(survey_id: PRE_SURVEY, type: STATS)
    Carnival.create(survey_id: PRE_SURVEY, type: SETTING)
  end

  def self.clear_data
    Carnival.destroy_all
  end

  def self.pre_survey_finished(answer_id)
	  binding.pry
    answer = Answer.find(answer_id)
    carnival_user = answer.carnival_user
    # check whether pass the pre survey
    if !answer.answer_content["5385919deb0e5b7282000004"]["selection"].include?(2321351209913222)
      result = false
    elsif answer.answer_content["538591d6eb0e5b7282000007"]["selection"].length == 1 && answer.answer_content["538591d6eb0e5b7282000007"]["selection"].include?(802546303491228)
      result = false
    else
      result = self.check_pre_survey_quota(answer)
    end
    carnival_user.pre_survey_result(result)
    carnival_user.hide_survey(answer) if result
    self.update_survey_quota(answer, PRE_SURVEY) if result
  end

  def self.check_pre_survey_quota(answer)
    quota_setting = self.where(survey_id: PRE_SURVEY, type: SETTING).first
    quota_stats = self.where(survey_id: PRE_SURVEY, type: STATS).first

    gender_qid = "538591f8eb0e5b7282000009"
    gender_q = Question.find(gender_qid)
    # male, female
    [0, 1].each do |e|
      return true if quota_stats.quota["gender"][e] < quota_setting.quota["gender"][e] && answer.answer_content[gender_qid]["selection"][0] == gender_q.issue["items"][e]["id"]
    end

    age_qid = "5385920ceb0e5b728200000b"
    age_q = Question.find(age_qid)
    # age under 18, 19-24, 25-30, 31-35, 36-40, 41-50, 50+
    (0..6).to_a.each do |e|
      return true if quota_stats.quota["age"][e] < quota_setting.quota["age"][e] && answer.answer_content[age_qid]["selection"][e] == age_q.issue["items"][0]["id"]
    end
    
    edu_qid = "53859222eb0e5b245200000c"
    edu_q = Question.find(edu_qid)
    # edu under middle school, high school, collage, bachelor, master+
    (0..4).to_a.each do |e|
      return true if quota_stats.quota["education"][e] < quota_setting.quota["education"][e] && answer.answer_content[edu_qid]["selection"][0] == edu_q.issue["items"][e]["id"]
    end

    income_qid = "5385924eeb0e5b2452000011"
    income_q = Question.find(income_qid)
    # income under 2000
    return true if quota_stats.quota["income"][0] < quota_setting.quota["income"][0] && [income_q.issue["items"][0]["id"], income_q.issue["items"][1]["id"], income_q.issue["items"][2]["id"]].include?(answer.answer_content[income_qid]["selection"][0])
    # income 2000-3000
    return true if quota_stats.quota["income"][1] < quota_setting.quota["income"][1] && answer.answer_content[income_qid]["selection"][0] == income_q.issue["items"][3]["id"]
    # income 3000-6000
    return true if quota_stats.quota["income"][2] < quota_setting.quota["income"][2] && [income_q.issue["items"][4]["id"], income_q.issue["items"][5]["id"], income_q.issue["items"][6]["id"]].include?(answer.answer_content[income_qid]["selection"][0])
    # income 6000-8000
    return true if quota_stats.quota["income"][3] < quota_setting.quota["income"][3] && [income_q.issue["items"][7]["id"], income_q.issue["items"][8]["id"]].include?(answer.answer_content[income_qid]["selection"][0])
    # income 8000-10000
    return true if quota_stats.quota["income"][4] < quota_setting.quota["income"][4] && answer.answer_content[income_qid]["selection"][0] == income_q.issue["items"][9]["id"]
    # income 10000+
    return true if quota_stats.quota["income"][5] < quota_setting.quota["income"][5] && [income_q.issue["items"][10]["id"], income_q.issue["items"][11]["id"], income_q.issue["items"][12]["id"], income_q.issue["items"][13]["id"], income_q.issue["items"][14]["id"]].include?(answer.answer_content[income_qid]["selection"][0])

    region_qid = "53859237eb0e5b245200000f"
    region_q = Question.find(region_qid)
    # region beijing, shanghai, guangzhou, shenzhen, tianjin, nanjing, wuhan, shenyang, xi'an, chengdu, chongqing, hangzhou, tsingdao,
    # dalian, ningbo, jinan, harbin, changchun, xiamen, zhengzhou, suzhou, wuxi, changsha, fuzhou, lanzhou, urumchi, kunming
    code = ["4096", "36864", "77888", "78016", "8192", "41024", "69696", "24640", "110656", "94272", "90112", "45120", "61568", "24704", "45184", "61504", "32832", "28736", "53376", "65600", "41088", "73792", "53312", "114752", "127040", "102464"]
    code.each_with_index do |c, index|
      return true if quota_stats.quota["region"][c] < quota_setting.quota["region"][c] && QuillCommon::AddressUtility.satisfy_region_code?(answer.answer_content[region_qid]["address"], c)
    end
    # other cities
    return false if code.include?(answer.answer_content[region_qid]["address"].to_s)
    (1..7).to_a.each do |c|
      return true if quota_stats.quota["region"][c.to_s] < quota_setting.quota["region"][c.to_s] && QuillCommon::AddressUtility.satisfy_big_region?(answer.answer_content[region_qid]["address"], c)
    end
    return false
  end

  def self.update_survey_quota(answer, survey_id)
    quota_stats = self.where(survey_id: survey_id, type: STATS).first

    gender_qid = "538591f8eb0e5b7282000009"
    gender_q = Question.find(gender_qid)
    # male, femail
    [0, 1].each do |e|
      quota_stats.quota["gender"][e] += 1 if answer.answer_content[gender_qid]["selection"][0] == gender_q.issue["items"][e]["id"]
    end

    age_qid = "5385920ceb0e5b728200000b"
    age_q = Question.find(age_qid)
    # age under 18, 19-24, 25-30, 31-35, 36-40, 41-50, 50+
    (0..6).to_a.each do |e|
      quota_stats.quota["age"][e] += 1 if answer.answer_content[age_qid]["selection"][0] == age_q.issue["items"][e]["id"]
    end
      
    edu_qid = "53859222eb0e5b245200000c"
    edu_q = Question.find(edu_qid)
    # edu under middle school, high school, collage, bachelor, master+
    (0..4).to_a.each do |e|
      quota_stats.quota["education"][e] += 1 if answer.answer_content[edu_qid]["selection"][0] == edu_q.issue["items"][e]["id"]
    end

    income_qid = "5385924eeb0e5b2452000011"
    income_q = Question.find(income_qid)
    # income under 2000
    quota_stats.quota["income"][0] += 1 if [income_q.issue["items"][0]["id"], income_q.issue["items"][1]["id"], income_q.issue["items"][2]["id"]].include?(answer.answer_content[income_qid]["selection"][0])
    # income 2000-3000
    quota_stats.quota["income"][1] += 1 if answer.answer_content[income_qid]["selection"][0] == income_q.issue["items"][3]["id"]
    # income 3000-6000
    quota_stats.quota["income"][2] += 1 if [income_q.issue["items"][4]["id"], income_q.issue["items"][5]["id"], income_q.issue["items"][6]["id"]].include?(answer.answer_content[income_qid]["selection"][0])
    # income 6000-8000
    quota_stats.quota["income"][3] += 1 if [income_q.issue["items"][7]["id"], income_q.issue["items"][8]["id"]].include?(answer.answer_content[income_qid]["selection"][0])
    # income 8000-10000
    quota_stats.quota["income"][4] += 1 if answer.answer_content[income_qid]["selection"][0] == income_q.issue["items"][9]["id"]
    # income 10000+
    quota_stats.quota["income"][5] += 1 if [income_q.issue["items"][10]["id"], income_q.issue["items"][11]["id"], income_q.issue["items"][12]["id"], income_q.issue["items"][13]["id"], income_q.issue["items"][14]["id"]].include?(answer.answer_content[income_qid]["selection"][0])

    region_qid = "53859237eb0e5b245200000f"
    region_q = Question.find(region_qid)
    # region beijing, shanghai, guangzhou, shenzhen, tianjin, nanjing, wuhan, shenyang, xi'an, chengdu, chongqing, hangzhou, tsingdao,
    # dalian, ningbo, jinan, harbin, changchun, xiamen, zhengzhou, suzhou, wuxi, changsha, fuzhou, lanzhou, urumchi, kunming
    code = ["4096", "36864", "77888", "78016", "8192", "41024", "69696", "24640", "110656", "94272", "90112", "45120", "61568", "24704", "45184", "61504", "32832", "28736", "53376", "65600", "41088", "73792", "53312", "114752", "127040", "102464"]
    code.each do |c|
      quota_stats.quota["region"][c] += 1 if QuillCommon::AddressUtility.satisfy_region_code?(answer.answer_content[region_qid]["address"], c)
    end
    # other cities
    if !code.include?(answer.answer_content[region_qid]["address"].to_s)
      (1..7).to_a.each do |c|
        quota_stats.quota["region"][c.to_s] += 1 if QuillCommon::AddressUtility.satisfy_big_region?(answer.answer_content[region_qid]["address"], c)
      end
    end
    quota_stats.save
    return
  end

  def self.background_survey_finished(answer_id)
    answer = Answer.find(answer_id)
    carnival_user = answer.carnival_user
    carnival_user.update_attributes(background_survey_status: CarnivalUser::FINISH)
  end

  def self.survey_finished(answer_id)
    answer = Answer.find(answer_id)
    carnival_user = answer.carnival_user
    carnival_user.survey_finished(answer.survey_id)
  end

  def self.survey_reviewed(answer_id)
    answer = Answer.find(answer_id)
    carnival_user = answer.carnival_user
    carnival_user.survey_reviewed(answer.survey_id, answer.status)
  end
end
