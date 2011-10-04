module NoahAgent
  class Http
    include NoahAgent::Worker
    ENDPOINT_PATTERN = "http://"

    def work(ep, msg)
      LOGGER.info("#{self.class.to_s} - Sending message to: #{ep}")
      Excon.post(ep, :body => msg)
    end

  end
end

