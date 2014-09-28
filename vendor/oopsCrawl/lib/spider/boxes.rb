require './lib/model/box'

module Spider

  module Boxes
    REG_NUM = /\d+\.?\d+/
    def initialize
      @boxes_spider = MicroSpider.new
      super
    end

    def crawl_boxes(date = nil)
      @boxes_spider.reset
      @boxes_spider.delay = 1.5
      date ||= Time.at(@movie.info_show_at).strftime('%Y%m%d')
      learn_boxes(date)
      @boxes_spider.crawl
    end

    def learn_boxes(date)
      @boxes_spider.learn do
        site "http://58921.com/boxoffice/top/week"
        entrance "/#{date}"
        # entrance "?sort=time&start=10003&limit=20"

        create_action :save do |cresult|
          _created_at = Time.parse(@date)
          cresult[:field].each do |field|
            field[:box].each do |item|
              next unless item.present?
              item[:created_at] = _created_at
              Box.create(item) 
            end
          end

        end
        
        fields :box, "#content .table-responsive tr" do |box_body|
          @date ||= date
          _info = {}
          #REG_NUM.match(comment_body.find(".rating").native.attr("class")).to_s.to_i
          next if box_body.first('th:eq(1)')
          @is_stop = true if box_body.first('.system_no_content')
          _info = {
            title: box_body.first('td:eq(1)').text,
            created_at: box_body.first('td:eq(1)').text,
            wangpiao: box_body.first('td:eq(3)').text.to_i,
            hapiao: box_body.first('td:eq(4)').text.to_i,
            gewala: box_body.first('td:eq(6)').text.to_i,
            wanda: box_body.first('td:eq(6)').text.to_i,
            jinyi: box_body.first('td:eq(6)').text.to_i,
            taodianying: box_body.first('td:eq(6)').text.to_i,
          }
        end

        save

        keep_eyes_on_next_page("#tabs li a:contains('下一周')") do |element|
          @date = (Time.parse(@date.to_s) + 1.weeks).strftime('%Y%m%d')
          @is_stop = true if Time.parse(@date.to_s) >= Time.now
          "http://58921.com/boxoffice/top/week/#{@date}"
        end

      end
    end

  end

end