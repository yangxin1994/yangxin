# already tidied up
class Admin::RewardSchemesController < Admin::AdminController

  layout "layouts/admin-todc"

  # *****************************

  def create
    options = make_attr(params[:reward_scheme])
    survey = Survey.find params[:reward_scheme][:survey_id]
    @reward_scheme = survey.reward_schemes.create(options)
    redirect_to "#{reward_schemes_admin_path(:id => params[:reward_scheme][:survey_id])}?editing=#{@reward_scheme._id}"
  end

  def update
    options = make_attr(params[:reward_scheme])
    @reward_scheme = RewardScheme.find(params[:id])
    @reward_scheme.update_attributes(options)
    redirect_to "#{reward_schemes_admin_path(:id => params[:reward_scheme][:survey_id])}?editing=#{params[:id]}"
  end

  def destroy
    if @reward_scheme = RewardScheme.where(:_id => params[:id]).first
      @reward_scheme.destroy
    end
    redirect_to reward_schemes_admin_path(:id => params[:reward_scheme][:survey_id])
  end

  def make_attr(options)
    reward_scheme_setting = {
      :rewards => [],
      :name => options[:name],
      :need_review => options[:need_review].to_s == 'on'
    }
    return reward_scheme_setting if options[:is_free].to_s == 'yes'
    options.each do |type, value|
      case type.to_sym
      when :tel_charge
        reward_scheme_setting[:rewards] << {
          :type => 1,
          :amount => value.to_i
        } if value.present?
      when :alipay
        reward_scheme_setting[:rewards] << {
          :type => 2,
          :amount => value.to_i
        } if value.present?
      when :point
        reward_scheme_setting[:rewards] << {
          :type => 4,
          :amount => value.to_i
        } if value.present?
      when :jifenbao
        reward_scheme_setting[:rewards] << {
          :type => 16,
          :amount => value.to_i
        } if value.present?
      when :hongbao
        reward_scheme_setting[:rewards] << {
          :type => 32,
          :amount => value.to_i
        } if value.present?        
      when :prizes
        prizes = []
        options[:prizes].each_value do |prize|
          if prize[:id].present?
            prize[:deadline] = Time.parse(prize[:deadline]).to_i
            prizes << prize
          end
        end
        reward_scheme_setting[:rewards] << {
          :type => 8,
          :prizes => prizes
        } if prizes.present?

      else

      end
    end

    reward_scheme_setting
  end
end