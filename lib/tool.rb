module Tool

	def email_illegal?(email)
		email.to_s.include?("@")
	end

end
