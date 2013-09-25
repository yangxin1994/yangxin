#already tidied up
class Advertisement
    include Mongoid::Document
    include Mongoid::Timestamps
    
    field :title, :type => String
    field :linked, :type => String
    field :image_location, :type => String
    field :activate, :type => Boolean, :default => false
    
    belongs_to :user
    
    attr_accessible :title, :linked, :image_location, :activate

    validates_presence_of :title, :linked, :image_location
    validates_uniqueness_of :title
    
    #--
    # scope is same with class methods
    #++
    scope :unactivate, where(activate: false)
    scope :activated, where(activate: true)
    scope :list_by_title, ->(title){ where(title: title.to_s.strip) }
    
    index({ title: 1, activate: 1 }, { background: true })
    index({ activate: 1 }, { background: true })

    #--
    # instance methods
    #++
    
    #--
    # class methods
    #++

    class << self

        # CURD

        #*description*:
        # different with find method, find_by_id will return ErrorEnum if not found.
        #
        #*params*:
        #* advertisement_id
        #
        #*retval*:
        #* ErrorEnum or advertisement instance
        def find_by_id(advertisement_id)
            advertisement = Advertisement.where(_id: advertisement_id.to_s).first
            return ErrorEnum::ADVERTISEMENT_NOT_EXIST if advertisement.nil?
            return advertisement
        end

    end
    
end
