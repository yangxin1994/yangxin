class TudouClient
    include HTTParty
    base_uri 'api.tudou.com/v3'

    @@auth = {
        username: 'market@oopsdata.com', 
        password: 'oopsdata@2012'
    }

    def self.video_upload_path
        begin
            return get('/gw?method=item.upload&title=oopsdata&tags=tg&channelId=1&appKey=763a7cbc2e91cdaa', 
                { basic_auth: @@auth }).parsed_response
        rescue Exception => e
            Rails.logger.error 'Failed to get video_upload_path info from tudou.com'
            Rails.logger.error e
            return nil
        end
    end

    def self.video_pic_url(video_code)
        begin
            result = get("/gw?method=item.info.get&appKey=763a7cbc2e91cdaa&format=json&itemCodes=#{video_code}")
            Rails.logger.debug result.inspect
            return result.parsed_response['multiResult']['results'][0]['picUrl']
        rescue Exception => e
            Rails.logger.error 'Failed to get video info from tudou.com'
            Rails.logger.error e
            return nil
        end
    end
end