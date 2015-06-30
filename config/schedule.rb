# set :output, {
#     :error    => "#{path}/log/error.log",
#     :standard => "#{path}/log/cron.log"
# }
case @environment
when 'production'
	every 10.minutes do
		runner "EmailInvitationWorker.perform_async"
	end
	
	every :hour do
	  runner "Wechart.batch_refresh_tasks"	
	end
	
	every 1.days, :at => '4:30 pm' do
		runner "SmsInvitationWorker.perform_async"
	end
	
	every 1.weeks do
		runner "SampleAttribute.make_statistics"
	end
	
	every 1.days, :at => '1:00 am' do
		runner 'Order.refresh_esai_orders'
	end
	
	every 1.days, :at => '0:00 am' do
		runner 'Order.recharge_fail_mobile'
	end
end