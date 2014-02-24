require 'tool'
class Client

  include Mongoid::Document
  include Mongoid::Timestamps
  include FindTool

  NORMAL = 1
  DELETED = 2

  field :email, :type => String
  field :password, :type => String
  field :name, :type => String
  field :status, :type => Integer, default: NORMAL
  field :auth_key, :type => String

  has_many :surveys

  scope :normal, where(:status => NORMAL)

  index({ status: 1 }, { background: true } )
  index({ auth_key: 1 }, { background: true } )
  index({ email: 1, password: 1 }, { background: true } )

  # Class Methods
  def self.create_client(client)
    return ErrorEnum::CLIENT_EXIST if !self.normal.find_by_email(client["email"]).nil?
    client["password"] = Encryption.encrypt_password(client["password"])
    client = Client.new(client)
    client.save
    return client
  end

  def self.find_by_auth_key(auth_key)
    return nil if auth_key.blank?
    client = self.normal.where(:auth_key => auth_key).first
    return nil if client.nil?
    return client
  end

  def self.search_client(email)
    clients = self.normal
    clients = clients.where(:email => /#{email.to_s}/) if !email.blank?
    return clients
  end

  def self.login(email, password)
    client = Client.where(:email => email, :password => Encryption.encrypt_password(password)).first
    client.auth_key = Encryption.encrypt_auth_key("#{client.email}&#{Time.now.to_i.to_s}")
    client.save
    client.auth_key
  end

  def self.logout(auth_key)
    client = self.find_by_auth_key(auth_key)
    if !client.nil?
      client.auth_key = nil
      client.save
    end
  end

  # Instance Methods
  def update_client(client)
    if client[:password].present?
      client[:password] = Encryption.encrypt_password(client[:password])
    else
      client.delete :password
    end
    return self.update_attributes(client)
  end

  def delete_client
    self.status = DELETED
    return self.save
  end

  def reset_password(old_password, new_password)
    return ErrorEnum::WRONG_PASSWORD if self.password != Encryption.encrypt_password(old_password)
    self.password = Encryption.encrypt_password(new_password)
    return self.save
  end

  def login
    self.auth_key = Encryption.encrypt_auth_key("#{self.email}&#{Time.now.to_i}")
    save and auth_key
  end

end
