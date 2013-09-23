# encoding: utf-8
# already tidied up

module GiftsHelper

    def gift_type_tag(status)
        tag = ""
        case status.to_i
        when 1
            tag = '<span class="label label-warning">虚拟</span>'
        when 2
            tag = '<span class="label label-success">实物</span>'
        when 4
            tag = '<span class="label label-important">话费</span>'
        when 8
            tag = '<span class="label label-important">支付宝</span>'
        when 16
            tag = '<span class="label label-important">集分宝</span>'
        when 32
            tag = '<span class="label label-warning">Q币</span>'
        end
        tag.html_safe
    end

end
