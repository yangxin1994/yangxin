class Photo

  include Mongoid::Document

  field :url, :type => String
  field :title, :type => String
  field :saved, :type => Boolean, :default => false

  belongs_to :movie


end