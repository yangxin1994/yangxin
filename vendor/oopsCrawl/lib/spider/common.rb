module Spider

  module Common

    REG_NUM = /\d+/

    def results(ret)
      items = []
      ret.results[0][:follow][0].each do |item|
        merged_item = {}
        item[:field].each { |field| merged_item.merge!(field) }
        items << merged_item
      end
      @results = items
    end

    get_count_and_url = lambda do |element|
      {
        text: REG_NUM.match(element.text).to_s.to_i,
        href: element.native.attributes['href'].value
      }
    end
    
  end
end