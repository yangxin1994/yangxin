#encoding: utf-8

module LotteriesHelper
	def prizes_tag(lottery)	  
		lottery["prizes"].map do |prize|
			"<option value=\"#{prize["_id"]}\">#{prize["name"]}</option>\n"
		end.join.html_safe
	end

	def lottery_status(status)
		case status
		when 0
			"未发布"
		when 1
			"显示在QuillMe"
		when 2
			"暂停"
		when 3
			"正在抽奖"
		end
	end

	def lottery_code_status(status)
		case status
		when 0
			"未抽奖"
		when 1
			"未抽中"
		when 2
			"抽中未下订单"
		when 3
			"抽中已下订单"
		end
	end

	def lottery_img(lottery)
		"<img style='max-width: 600px;' src=\"#{lottery["photo_src"]}\" alt=\"#{lottery["title"]}\"/>".html_safe
	end

	def prizes_tag(prizes)
		return @prize_tag_l if @prize_tag_l
		s1 = "<select class=\"ctrl_prize\" name = \"prize\">"
    s2 = prizes.map do |prize|
      "<option value=\"#{prize['_id']}\">#{prize['name']}    剩余:#{prize['surplus']}件</option>"
    end.join
    s3 = "</select>"
		@prize_tag_l = (s1 + s2 + s3).html_safe
	end

	def ck_public_tag(lottery)
		if lottery["status"].to_s == "3" || lottery["status"].to_s == "2"
			'checked'.html_safe 
		end
	end

	def ck_display_tag(lottery)
		if lottery["status"].to_s == "3" || lottery["status"].to_s == "1"
			'checked'.html_safe 
		end
	end
end
