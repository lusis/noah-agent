module NoahAgent
  class Dummy
    include NoahAgent::Worker
    ENDPOINT_PATTERN = "dummy://"

    def work(ep, msg)
      LOGGER.info("Got a message for #{ep}: #{msg}")
      sleep 30
      LOGGER.info("Processed dummy message")
    end

  end
end
