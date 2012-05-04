module RailsEnv
	#If no parameters are given, return the current environment; else return boolean value to indicate whether current environment is equal to the given parameter
	def self.get_rails_env(env=nil)
		env == nil ? Rails.env : (env == Rails.env)
	end
end
