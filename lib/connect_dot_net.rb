#encoding: utf-8
module ConnectDotNet
  def send_data(post_to)
    url = URI.parse(Rails.application.config.dotnet_web_service_uri)
    begin
      Net::HTTP.start(url.host, url.port) do |http| 
        r = Net::HTTP::Post.new(post_to)
        r.set_form_data(yield)
        http.read_timeout = 120
        retval = http.request(r)
        return retval
      end
    rescue Errno::ECONNREFUSED
      logger.info  "servive refused"
      return ErrorEnum::DOTNET_SERVICE_REFUSED
    rescue Timeout::Error
      logger.info  "timeout"
      return ErrorEnum::DOTNET_TIMEOUT
    ensure
      # export_process[:post] = 100
      # self.save
    end
  end
  
  def get_data(get_from)
    url = URI.parse(Rails.application.config.dotnet_web_service_uri)
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
      logger.info "连接失败"
    rescue Timeout::Error
      p "超时"
    ensure
      p "连接结束"
    end
  end
end
