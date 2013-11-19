class Sample::HomesController < Sample::SampleController

  def show
    hot_survey     = Survey.quillme_promote.quillme_hot.opend.first
    surveys = Survey.get_recommends(sample:current_user,home_page:true)
    params[:per_page] = 9

    rsl = auto_paginate(surveys) do |paginated_surveys|
      paginated_surveys.map { |e| e.excute_sample_data(current_user) } 
    end

    public_notices = PublicNotice.desc(:top).opend.desc(:created_at).limit(5)
    hotest_gifts = Gift.on_shelf.real.desc(:view_count).limit(8)
    top_rank_users = User.sample.where(:is_block => false).desc(:point).limit(5)
    fresh_news = Log.get_new_logs(5, nil)

    @data = {
      hot_survey:hot_survey,
      rsl:rsl,public_notices:public_notices,
      hotest_gifts:hotest_gifts,
      top_rank_users:top_rank_users,
      fresh_news:fresh_news
    }
  end
end