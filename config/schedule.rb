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
	runner "QuotaEmailWorker.perform_async"
end

every 1.days do
	runner "ImportEmail.remove_bounce_emails"
end

every 1.days do
	command "cd ~/db_bak/; mongodump -d oops_data_production -o './' -u oopsdata -password=o2psllyscdata; tar -zcf oops_data_production_$(date +%d-%m-%y).tar.gz oops_data_production; rm -rf oops_data_production"
end
