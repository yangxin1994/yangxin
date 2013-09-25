#encoding: utf-8
class BrowserHistory
    include Mongoid::Document
    include FindTool
    
    field :url, :type => String
    field :title, :type => String
    field :last_visit_time, :type => Integer
    field :visit_count, :type => Integer
    field :typed_count, :type => Integer

    belongs_to :browser

    index({ url: 1 }, { background: true } )

end
