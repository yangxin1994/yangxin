# encoding: utf-8
require 'cgi'
class Travel::CitiesController < Travel::TravelController
	def index
		if request.xhr?
			date_arr  = ajax_data(params[:year],params[:month],params[:act])
			@year     = date_arr[0]
			@month    = date_arr[1]
		else
			@year  = Time.now.year
			@month = Time.now.month			
		end

		range_arr  = convert_range(@year,@month)

		@from      = range_arr[0]
		@to        = range_arr[1]
		@quarter   = range_arr[2]


		@data = Hash.new(0)
		supervisor = Supervisor.where(user_id:current_user.id.to_s).first
		survey_ids = supervisor.surveys.where(:created_at.gte => @from,:created_at.lte => @to).map(&:id)
		# survey_ids = Survey.where(title:/全国游客满意度调查/,:created_at.gte => @from,:created_at.lte => @to).map(&:id)

		tasks      = InterviewerTask.where(:survey_id.in => survey_ids)

		tasks.each do |task|
			@data[task.city]             = {amount:0,finished:0,checked:0} if @data[task.city] == 0 	
			@data[task.city][:amount]   += task.quota['rules'][0]['amount']
			@data[task.city][:finished] += task.quota['submitted_count']
			@data[task.city][:checked]  += task.quota['finished_count']
			@data[task.city][:finish_percent] = ((@data[task.city][:finished] / @data[task.city][:amount].to_f) * 100).to_s + '%'
			@data[task.city][:check_percent] = ((@data[task.city][:checked] / @data[task.city][:amount].to_f) * 100).to_s + '%'
		end
		@data['year']    = @year
		@data['month']   = @month
		@data['from']    = @from
		@data['to']      = @to 
		@data['quarter'] = @quarter

		if request.xhr?
			render_json_auto @data
		end
	end

	def show
		if request.xhr?
			date_arr  = ajax_data(params[:year],params[:month],params[:act])
			@year     = date_arr[0]
			@month    = date_arr[1]
		else
			@from  =  DateTime.parse(params[:from]).strftime('%F')
			@to    =  DateTime.parse(params[:to]).strftime('%F')

			@year  = @from.split('-')[0].to_i
			@month = @from.split('-')[1].to_i
		end


		range_arr  = convert_range(@year,@month)

		@from      = range_arr[0]
		@to        = range_arr[1]
		@quarter   = range_arr[2]		

		@city   = CGI::unescape(params[:id])
		tasks   = InterviewerTask.where(:city.ne => nil).select{|task| task.city.match(/^#{@city}$/)}

		@surveys = []
		tasks.each do |task|
			survey = task.survey
			if survey.created_at >= @from && survey.created_at <= @to && survey.title.match(/全国游客满意度调查/)
				interviewer_tasks = survey.interviewer_tasks.where(city:/^#{@city}$/)
				survey.write_attributes(amount:interviewer_tasks.map{|t| t.quota['rules'][0]['amount']}.inject{|sum,x| sum + x})
				survey.write_attributes(finish:interviewer_tasks.map{|t| t.quota['submitted_count']}.inject{|sum,x| sum + x})
				survey.write_attributes(suffice:interviewer_tasks.map{|t| t.quota['finished_count']}.inject{|sum,x| sum + x})
				interviews = []
				interviewer_tasks.each do |t|
					t.write_attributes(nickname:t.user.nickname)
					finish_percent = ( ( (t.quota['submitted_count'] / t.quota['rules'][0]['amount'].to_f) * 100 ).to_s + '%' )
					suffice_percent = ( ( (t.quota['finished_count'] / t.quota['rules'][0]['amount'].to_f) * 100 ).to_s + '%' )
					t.write_attributes(finish_percent:finish_percent)
					t.write_attributes(suffice_percent:suffice_percent)
					interviews << t
				end
				survey.write_attributes(interviews:interviews)
				@surveys << task.survey  if !@surveys.include?(survey)
			end
		end

		@surveys << {year:@year,month:@month,from:@from,to:@to,quarter:@quarter,city:@city}
		Rails.logger.info('=============================================')
		Rails.logger.info(@surveys.inspect)
		Rails.logger.info('=============================================')
		if request.xhr?
			render_json_auto @surveys
		end
	

	end


	private 
	def convert_range(year,month)
		if month <= 3
			from    = DateTime.new(year,1,1)
			to      = DateTime.new(year,3,31)
			quarter = "#{@year}年第一季度" 
		elsif month <= 6
			from    = DateTime.new(year,4,1)
			to      = DateTime.new(year,6,30)
			quarter = "#{@year}年第二季度" 		
		elsif month <= 9
			from    = DateTime.new(year,7,1)
			to      = DateTime.new(year,9,30)	
			quarter = "#{@year}年第三季度" 			
		elsif month <= 12
			from    = DateTime.new(year,10,1)
			to      = DateTime.new(year,12,31)	
			quarter = "#{@year}年第四季度" 	
		end
		return [from,to,quarter]		
	end

	def ajax_data(year,month,act)

			c_year = year.to_i
			c_mon  = month.to_i
			date   = Date.new(c_year.to_i,c_mon.to_i)			
			if act == 'prev'
				d  = date - 3.month
			else
				d  = date + 3.month
			end
			return [d.year,d.month]

	end

end

