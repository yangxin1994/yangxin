#encoding: utf-8
module ConnectDotNet
    def send_data(post_to)
      url = URI.parse('http://192.168.1.107:9292')
      begin
        Net::HTTP.start(url.host, url.port) do |http| 
          r = Net::HTTP::Post.new(post_to)
          a = Time.now
          r.set_form_data(yield)
          p Time.now - a
          http.read_timeout = 120
          p "000000000"
          p url.host
          p url.port
          p post_to
          p "111111111"
          http.request(r)
        end
      rescue Errno::ECONNREFUSED
        p "aaa"
      rescue Timeout::Error
        p "bbb"
      ensure
        # export_process[:post] = 100
        # self.save
        p "ccc"
      end
    end
    
    def get_data(get_from)
      url = URI.parse('http://192.168.1.107:9292')
      begin
        Net::HTTP.start(url.host, url.port) do |http| 
          r = Net::HTTP::Get.new(get_from)
          a = Time.now
          r.set_form_data(yield)
          p Time.now - a
          http.read_timeout = 120
          p "===== 准备连接 ====="
          http.request(r)
        end
      rescue Errno::ECONNREFUSED
        p "连接失败"
      rescue Timeout::Error
        p "超时"
      ensure
        # export_process[:post] = 100
        # self.save
        p "连接结束"
      end
    end
end
