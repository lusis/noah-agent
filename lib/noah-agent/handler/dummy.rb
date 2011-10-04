module NoahAgent
  class Dummy
    include NoahAgent::Worker
    ENDPOINT_PATTERN = "dummy://"

    def work(ep, msg)
      LOGGER.info("#{self.class.to_s} - Got a message for #{ep}: #{msg}")
      sleep 30
      LOGGER.info("#{self.class.to_s} - Processed dummy message")
    end

  end
end
