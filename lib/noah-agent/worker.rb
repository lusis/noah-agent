module Noah::Agent
  class Worker

    def self.inherited(model)
      model.send :include, Celluloid::Actor
    end

    attr_accessor :name, :busy

    WORKER_PATTERN="nil://"
    MAX_CONCURRENCY=100

    def initialize(name)
      @name = name
      @busy = false
      Noah::Agent::LOGGER.info("Starting worker #{name} for pattern #{self.class::WORKER_PATTERN}")
    end

    def work(msg)
      @busy = true
      Thread.new do
        Noah::Agent::LOGGER.info "Worker #{@name} is working"
        sleep 10
        Noah::Agent::LOGGER.debug "Message is #{msg}"
        sleep 10
        Noah::Agent::LOGGER.info "Finished work"
      end
      @busy = false
    end

    def busy?
      @busy
    end
  end
end
