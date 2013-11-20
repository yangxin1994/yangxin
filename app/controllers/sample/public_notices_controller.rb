class Sample::PublicNoticesController < Sample::SampleController
  def index
    params[:per_page] = 15
    @public_notices = auto_paginate PublicNotice.desc(:top).opend.desc(:created_at)
  end

  def show
    @public_notice = PublicNotice.find_by_id(params[:id])
    render_404 if @public_notice.nil?
    pids = PublicNotice.opend.desc(:updated_at)
    tmp_hash = {}
    pids.each_with_index { |pid, index| tmp_hash["#{pid['_id']}"] = index } if pids.present?
    tmp_hash['current_notice'] = @public_notice
    @public_notice = tmp_hash
  end
end