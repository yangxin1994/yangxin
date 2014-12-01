# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every 10.minutes do
	runner "EmailInvitationWorker.perform_async"
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
