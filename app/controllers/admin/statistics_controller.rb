class Admin::StatisticsController < Admin::AdminController

  layout "layouts/statistics"
   
  def show
    smp_attr = SampleAttribute.find_by_id(params[:id])
    # binding.pry
    gon.analyze_result = smp_attr.analyze_result
  end

end