class Admin::StatisticsController < Admin::AdminController

  layout "layouts/statistics"
   
  def show
    @smp_attr = SampleAttribute.find_by_id(params[:id])
    gon.chart_type = @smp_attr.type
    gon.enum_array = @smp_attr.enum_array
    gon.analyze_result = @smp_attr.analyze_result
  end

end