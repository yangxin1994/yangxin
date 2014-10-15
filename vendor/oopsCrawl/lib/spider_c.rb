require File.expand_path("../spider", __FILE__) 
s = OopSpider.new()
l = OopSpider.new()
# s = OopSpider.new('25713408')
# # ============================
# s.crawl_weibos(线程数)
# s.crawl_reviews 
# s.crawl_nowplaying
# l.crawl_later
# Movie.where(subject_url:/mtime\.com/).each do |m|
#   if Time.now.to_i > m.info_show_at
#     m.update_attributes(nowplaying:true)
#   end
# 	unless m.photos.length > 0
# 		ps = OopSpider.new(m.subject_id.to_s)
# 		ps.crawl_photos
# 	end
# end 

# # ============================
# s.crawl_weibo_basic
binding.pry
