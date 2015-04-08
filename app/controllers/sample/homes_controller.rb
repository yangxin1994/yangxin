# encoding: utf-8
class Sample::HomesController < Sample::SampleController

  def show
    hot_survey     = Survey.quillme_promote.quillme_hot.opend.first
    surveys = Survey.get_recommends(sample:current_user,home_page:true)
    params[:per_page] = Survey::PER_PAGE

    rsl = auto_paginate(surveys) do |paginated_surveys|
      paginated_surveys.map { |e| e.excute_sample_data(current_user) } 
    end

    public_notices = PublicNotice.desc(:top).opend.desc(:created_at).limit(5)
    hotest_gifts = Gift.on_shelf.real.desc(:view_count).limit(5)
    top_rank_users = User.sample.where(:is_block => false).desc(:point).limit(5)
    fresh_news = Log.get_new_logs(5, nil)
    survey_counts = Survey.count.to_s.split('')
    answer_counts = Answer.where(:status => Answer::FINISH).count.to_s.split('')
    banners = Banner.all

    express_surveys = SurveyTask.quillme_promote.opend.desc(:created_at)
    express_surveys =  auto_paginate(express_surveys) do |paginated_surveys|
      paginated_surveys.map { |e| e.excute_sample_data(current_user) } 
    end

    #movies = Movie.rand(cookies[:vote_user_id])

    @data = {
      hot_survey:hot_survey,
      rsl:rsl,
      public_notices:public_notices,
      hotest_gifts:hotest_gifts,
      top_rank_users:top_rank_users,
      fresh_news:fresh_news,
      banners:banners,
      survey_counts:survey_counts,
      answer_counts:answer_counts,
      express_surveys:express_surveys
    }
  end

  def gifts
    params[:per_page] = 5
    hotest_gifts = Gift.unscoped.on_shelf.real
    hotest_gifts = hotest_gifts.desc(:view_count)
    @hotest_gifts = auto_paginate(hotest_gifts)
  end


end