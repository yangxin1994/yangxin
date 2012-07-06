class PublicNotice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, :type => String
  field :content, :type => String
  field :attachment, :type => String
  field :public_notice_type, :type => String

  belongs_to :user
  #--
  # instance methods
  #++u
  #

  #--
  # class methods
  #++
  
  class << self
    
    #*description*: create public notice 
    #
    #*params*:
    #* user: who create public notice and must be admin 
    #* public_notice_type: type for public notice
    #* title: notice 's title
    #* content: notice 's content
    #* attachment: notice 's attachment. it is nil in default.
    #
    #*retval*:
    #* false or true
    def create_by_user(user, public_notice_type, title, content, attachment = nil)
      return false if !user.instance_of?(User)
      return false if !user.is_admin
      public_notice = PublicNotice.new(user: user, public_notice_type: public_notice_type, 
      		title: title, content: content)
      public_notice.attachment = attachment if attachment
      return public_notice.save
    end 

    #*description*: update public notice
    #
    #*params*:
    #* user: who update public notice. he does not need to be creator, but must be admin.
    #* public_notice_id
    #* hash: public notice attrs. only receive attrs: public_notice_type, title, content, attachment
    #
    #*retval*:
    #* true or false 
    def update_by_user(public_notice_id, user, hash)
      
      return false if !user.instance_of?(User)
      return false if !user.is_admin

      public_notice = PublicNotice.find(public_notice_id)
      return false if public_notice.nil?

      hash.select!{|k,v| %{public_notice_type title content attachment}.split.include?(k.to_s)}
      public_notice.update_attributes(hash)
      return public_notice.save 
    end 

    #*description*: destroy public notice
    #
    #*params*:
    #* user: who update public notice. he does not need to be creator, but must be admin 
    #* public_notice_id
    #
    #*retval*:
    #*true or false 
    def destroy_by_user(public_notice_id, user)
      return false if !user.instance_of?(User)
      return false if !user.is_admin

      return PublicNotice.where(_id: public_notice_id).delete
    end
    
    def list_recently
    	return PublicNotice.all.desc(:updated_at)
    end

    #*description*: list public_notices with one condition
  	#
  	#*retval*:
    #public_notice array
    def condition(key, value)
      return nil if %{type title}.split.delete(key.to_s).nil?
    	return PublicNotice.where(public_notice_type: value).desc(:updated_at) if key.to_s == "type"
      return PublicNotice.where(title: /.*#{value}.*/).desc(:updated_at) if key.to_s == "title"
    end
  end 
end 
