(($)->
  $.fn.share = (opts) ->
    defaults = 
      title:''
      url:''
      pics:''

    options = $.extend {},defaults,opts

    return @.each ()->
      $this = $(@)
      $this.find('a').bind 'click',(event) ->
        event.preventDefault
        console.log("ddd")
        share($(@).attr('class'))

      share = (klass)->
        switch klass
          when 'sina'
            link = 'http://service.weibo.com/share/share.php?'
            param =
              link:link
              url: options.url
              title:options.title
              pic: options.pics
              appkey:''
              ralateUid:''
              language:'zh_cn' 
          when 'tecent'
            link = 'http://share.v.t.qq.com/index.php?'
            param =
              c:'share'
              a:'index'
              appkey:''
              site:''
              link:link
              url:options.url
              title:options.title
              pic:options.pics
          when 'douban'
            link = 'http://shuo.douban.com/!service/share?'
            param = 
              href:options.url
              name:options.title
              image:options.pics
          when 'renren'
            link = 'http://widget.renren.com/dialog/share?'
            param = 
              resourceUrl:options.url
              srcUrl:options.url
              title:options.title
              pic:options.pics
          when 'qzone'
            link = 'http://sns.qzone.qq.com/cgi-bin/qzshare/cgi_qzshare_onekey?'
            param = 
              url:options.url
              title:options.url
              pics:options.pics
          when 'kaixin'
            link = 'http://www.kaixin001.com/rest/records.php?'
            param = 
              url:options.url
              content:options.title
              pic:options.pics
              startid:''
              aid:''
              style:11
          when 'diandian'
            link = 'http://www.diandian.com/share?'
            param = 
              ti:options.title
              lo:options.url
              type:'link'
          when 'fetion'
            link = 'http://i2.feixin.10086.cn/app/api/share?'
            param = 
              Source: ''
              Title:options.title
              Url:options.url
          when 'gmail'
            link = 'https://mail.google.com/mail/?ui=2&view=cm&fs=1&tf=1&'
            param = 
              su:options.title
              body:options.url

        _share link,param

      _share = (link = null,param = null) ->
        if link? and param?
          tmp = null

          for key,value of param
            tmp += "&#{key}=#{encodeURIComponent(value)}"

          tmp = tmp.slice(1,tmp.length)

          window.open(link + tmp);       
)(jQuery)