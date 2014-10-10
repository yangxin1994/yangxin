require './lib/model/proxy'

module Spider

  module Proxies
    REG_NUM = /\d+\.?\d+/
    def initialize
      @proxies_spider = MicroSpider.new
      super
    end

    def crawl_proxies
      @proxies_spider.reset
      @proxies_spider.delay = 1.5
      learn_proxies
      @proxies_spider.crawl
    end

    def learn_proxies
      @proxies_spider.learn do
        site "http://www.xici.net.co"
        entrance "/nn"
        # entrance "?sort=time&start=10003&limit=20"

        create_action :save do |cresult|
          cresult[:field].each do |field|
            field[:proxy].each do |item|
              Proxy.create(item) if item.present?
            end
          end
        end
        
        fields :proxy, "#ip_list tr" do |proxy_body|
          #REG_NUM.match(comment_body.find(".rating").native.attr("class")).to_s.to_i
          begin
            {
              ip: proxy_body.find('td:eq(2)').text,
              port: proxy_body.find('td:eq(3)').text,
              location: proxy_body.find('td:eq(4)').text,
              type: proxy_body.find('td:eq(6)').text,
              speed: REG_NUM.match(proxy_body.find('td:eq(7) .bar').native.attr("title")).to_s.to_f,
              conn: REG_NUM.match(proxy_body.find('td:eq(8) .bar').native.attr("title")).to_s.to_f,
              created_at: Time.parse(proxy_body.find('td:eq(9)').text).to_i
            }
          rescue Exception => e
            {}
          end
        end

        save

        keep_eyes_on_next_page(".pagination a.next_page") if Proxy.count < 1000

      end
    end

  end

end