module Tool

	def self.email_illegal?(email)
		!email.to_s.include?("@")
	end

end
