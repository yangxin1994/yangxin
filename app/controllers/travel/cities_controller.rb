class Travel::CitiesController < Travel::TravelController
	def index
		if request.xhr?
			c_year = params[:year].to_i
			c_mon  = params[:month].to_i
			date   = Date.new(c_year.to_i,c_mon.to_i)			
			if params[:act] == 'prev'
				d = date - 3.month
			else
				d = date + 3.month
			end
			@year  = d.year
			@month = d.month 
		else
			@year  = Time.now.year
			@month = Time.now.month			
		end

		if @month <= 3
			@from    = DateTime.new(@year,1,1)
			@to      = DateTime.new(@year,3,31)
			@quarter = "#{@year}年第一季度" 
		elsif @month <= 6
			@from    = DateTime.new(@year,4,1)
			@to      = DateTime.new(@year,6,30)
			@quarter = "#{@year}年第二季度" 		
		elsif @month <= 9
			@from    = DateTime.new(@year,7,1)
			@to      = DateTime.new(@year,9,30)	
			@quarter = "#{@year}年第三季度" 			
		elsif @month <= 12
			@from    = DateTime.new(@year,10,1)
			@to      = DateTime.new(@year,12,31)	
			@quarter = "#{@year}年第四季度" 	
		end

		@data = Hash.new(0)

		survey_ids = Survey.where(title:/全国游客满意度调查/,:created_at.gte => @from,:created_at.lte => @to).map(&:id)

		tasks      = InterviewerTask.where(:survey_id.in => survey_ids)

		tasks.each do |task|
			@data[task.quota['rules'][0]['city']]             = {amount:0,finished:0,checked:0} if @data[task.quota['rules'][0]['city']] == 0 	
			@data[task.quota['rules'][0]['city']][:amount]   += task.quota['rules'][0]['amount']
			@data[task.quota['rules'][0]['city']][:finished] += task.quota['rules'][0]['finished_count']
			@data[task.quota['rules'][0]['city']][:checked]  += task.survey.answers.where(status:Answer::FINISH).count
			@data[task.quota['rules'][0]['city']][:finish_percent] = ((@data[task.quota['rules'][0]['city']][:finished] / @data[task.quota['rules'][0]['city']][:amount].to_f) * 100).to_s + '%'
			@data[task.quota['rules'][0]['city']][:check_percent] = ((@data[task.quota['rules'][0]['city']][:checked] / @data[task.quota['rules'][0]['city']][:amount].to_f) * 100).to_s + '%'
		end
		@data['year']    = @year
		@data['month']   = @month
		@data['from']    = @from
		@data['to']      = @to 
		@data['quarter'] = @quarter
		Rails.logger.info('--------------------------------')
		Rails.logger.info(@data.inspect)
		Rails.logger.info('--------------------------------')

		# if request.xhr?
		# 	render_json_auto @data
		# end

	end

	def show
		@city    = params[:id]
		@from    = params[:from].strftime('%F')
		@to      = params[:to].strftime('%F')
		return travel_path unless params[:from].present?
		return travel_path unless params[:to].present?
		tasks   = InterviewerTask.all.select{|task| task.quota['rules'][0]['city'] == city}
		@surveys = []
		tasks.each do |task|
			survey = task.survey
			if survey.created_at.strftime('%F') >= from && survey.created_at.strftime('%F') <= to
				@surveys << task.survey if task.survey.title.match(/全国游客满意度调查/)
			end
			
		end
	end
end

