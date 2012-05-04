#Provide methods for reading and writing caches
module Cache
	#Write to cache. The expiration time can be set by passing parameters, as follows:
	# Cache.write("key", "value", :expires_in => 1.days)
	def self.write(key, value, opt = {})
		Rails.cache.write(OOPSDATA[RailsEnv.get_rails_env]["cache_key_prefix"] + key.to_s, value, :expires_in => opt[:expires_in] || OOPSDATA[RailsEnv.get_rails_env]['cache_expiration'].to_i.seconds)
	end

	#Read from cache
	def self.read(key)
		Rails.cache.read(OOPSDATA[RailsEnv.get_rails_env]["cache_key_prefix"] + key.to_s)
	end

end
