module Net
  class HTTP
    def use_ssl=(flag)
      flag = flag ? true : false
      if started? and @use_ssl != flag
        raise IOError, "use_ssl value changed, but session already started"
      end
      @use_ssl = flag
      if @use_ssl
        self.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end
end