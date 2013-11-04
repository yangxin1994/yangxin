class Admin::StatisticsController < Admin::AdminController

  layout "layouts/statistics"
   
  def show
    @smp_attr = SampleAttribute.find_by_id(params[:id])
    gon.chart_type = @smp_attr.type
    gon.date_type = @smp_attr.date_type
    gon.enum_array = @smp_attr.enum_array
    gon.analyze_requirement = @smp_attr.analyze_requirement
    gon.analyze_result = @smp_attr.analyze_result
  end

end