#encoding: utf-8
class MailgunApi

	@@test_email = "test@oopsdata.com"

	@@survey_email_from = "postmaster@oopsdata.net"
	@@survey_email_to = "postmaster@oopsdata.net"

	def self.send_survey_email(user_id, email, survey_id_ary)
		if user_id.blank?
			@email = email
		else
			user = User.find_by_id(user_id)
			@email = user.email
			return if @email.blank?
		end


		@surveys = survey_id_ary.map { |e| Survey.find_by_id(e) }
		@presents = []	
		# push a lottery
		lottery = Lottery.quillme.first
		@presents << {:title => lottery.title,
			:url => "#{Rails.application.config.quillme_host}/lotteries/#{lottery._id.to_s}",
			:img_url => Rails.application.config.quillme_host + lottery.photo_url} if !lottery.nil?
		# push a real gift
		real_gift = BasicGift.where(:type => 1, :status => 1).first
		@presents << {:title => real_gift.name,
			:url => "#{Rails.application.config.quillme_host}/gifts/#{real_gift._id.to_s}",
			:img_url => Rails.application.config.quillme_host + real_gift.photo.picture_url} if !real_gift.nil?
		# push a cash gift
		cash_gift = BasicGift.where(:type => 0, :status => 1).first
		@presents << {:title => cash_gift.name,
			:url => "#{Rails.application.config.quillme_host}/gifts/#{cash_gift._id.to_s}",
			:img_url => Rails.application.config.quillme_host + cash_gift.photo.picture_url} if !cash_gift.nil?

		data = {}
		data[:domain] = Rails.application.config.survey_email_domain
		data[:from] = @@survey_email_from
		data[:subject] = "邀请您参加问卷调查"
		html_template_file_name = "#{Rails.root}/app/views/survey_mailer/survey_email.html.erb"
		text_template_file_name = "#{Rails.root}/app/views/survey_mailer/survey_email.text.erb"

		html_template = ERB.new(File.new(html_template_file_name).read, nil, "%")
		text_template = ERB.new(File.new(text_template_file_name).read, nil, "%")
		premailer = Premailer.new(html_template.result(binding), :warn_level => Premailer::Warnings::SAFE)
		data[:html] = premailer.to_inline_css
		data[:text] = text_template.result(binding)

		data[:to] = Rails.env == "production" ? @email : @@test_email
		data[:subject] = Rails.env == "production" ? "邀请您参加问卷调查" : "邀请您参加问卷调查 --- to #{@email}"
		self.send_message(data)
	end

	def self.send_message(data)
		domain = data.delete(:domain)
		retval = RestClient.post("https://api:#{Rails.application.config.mailgun_api_key}"\
		  "@api.mailgun.net/v2/#{domain}/messages", data)
		begin
			retval = JSON.parse(retval)
			return retval["id"]
		rescue
			return -1
		end
	end
end
