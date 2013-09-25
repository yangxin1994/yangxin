#encoding: utf-8
class BrowserExtension
    include Mongoid::Document
    include Mongoid::Timestamps
    include FindTool
    field :version, :type => String
    field :browser_extension_type, :type => String
    field :appid, :type => String
    field :codebase, :type => String
    has_many :browsers

    index({ browser_extension_type: 1 }, { background: true } )
end
