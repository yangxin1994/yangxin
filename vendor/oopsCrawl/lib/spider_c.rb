require File.expand_path("../spider", __FILE__) 
require 'sidekiq'
require 'sidekiq-cron'

s = OopSpider.new()
l = OopSpider.new()
# s = OopSpider.new('25713408')
# # ============================
# s.crawl_weibos(线程数)
# s.crawl_reviews 
# s.crawl_nowplaying
# l.crawl_later


# Movie.each do |m|
#   if Time.now.to_i > m.info_show_at
#     m.update_attributes(nowplaying:true)
#   end   
#   if m.subject_url.match(/mtime/)
#     unless m.photos.length > 0
#       ps = OopSpider.new(m.subject_id.to_s)
#       ps.crawl_photos
#     end      
#   end         
# end

#Sidekiq::Cron::Job.all
#Sidekiq::Cron::Job.destroy_all!




# # ============================
# s.crawl_weibo_basic
binding.pry
