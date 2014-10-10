require './lib/model/photo'

module Spider

  module Photos

    REG_NUM = /\d+/

    def initialize
      @photos_spider = MicroSpider.new

      super
    end

    def crawl_photos
      @photos_spider.reset
      @photos_spider.delay = 1.5
      learn_photos(@movie.subject_id)
      @photos_spider.crawl
    end

    def subject_id
      @movie.subject_id
    end

    def learn_photos(subject_id)
      @photos_spider.learn do
        site "http://movie.douban.com/subject/#{subject_id}/photos?type=R&sortby=vote"
        entrance "/"

        create_action :save_photo do |cresult|
          _result = {}
          @movie = Movie.where(:subject_id => subject_id).first
          if @movie.photos.length <= 0
            cresult[:field].each { |field| _result.merge!(field) }
            _result[:photos].each do |_photo|
              # if photo = photo.where(:photo_id => _photo[:photo_id]).first
                # "跳过~~"
              # else
                photo = Photo.create(_photo)
                @movie.photos << photo
              # end
            end
            @movie.save          
          end
        end

        fields :photos, ".poster-col4 li" do |photo|
          next unless photo.first(".cover a img")
          {
            :url => photo.first(".cover a img").native.attr('src').gsub('thumb', 'photo'),
            :title => photo.first(".name").text
          }
        end

        save_photo

      end
    end
  end

end