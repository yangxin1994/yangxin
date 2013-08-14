module Encryption

	def self.encrypt_password(string)
		key = EzCrypto::Key.with_password("password", "oops!data")
		return Base64.encode64(key.encrypt(string.to_s))
	end

	def self.decrypt_password(string)
		key = EzCrypto::Key.with_password("password", "oops!data")
		return key.decrypt(Base64.decode64(string.to_s))
	end

	def self.encrypt_auth_key(string)
		key = EzCrypto::Key.with_password("auth_key", "oops!data")
		return Base64.encode64(key.encrypt(string.to_s))
	end

	def self.encrypt_activate_key(string)
		key = EzCrypto::Key.with_password("activate_key", "oops!data")
		return Base64.encode64(key.encrypt(string.to_s))
	end

	def self.decrypt_activate_key(string)
		key = EzCrypto::Key.with_password("activate_key", "oops!data")
		return key.decrypt(Base64.decode64(string.to_s))
	end

	def self.encrypt_third_party_user_id(string)
		key = EzCrypto::Key.with_password("third_party_user_id", "oops!data")
		return Base64.encode64(key.encrypt(string.to_s))
	end

	def self.decrypt_third_party_user_id(string)
		key = EzCrypto::Key.with_password("third_party_user_id", "oops!data")
		return key.decrypt(Base64.decode64(string.to_s))
	end
end
