module Noah::Agent
  class Broker
    include Celluloid::Actor
    attr_reader :registered_workers

    def initialize
      LOGGER.info("Starting broker actor")
    end

    def register_worker(worker)
      LOGGER.info("Registering worker: #{worker}")
    end

    def scale_worker(worker, count)
      LOGGER.info("Scaling worker #{worker} by #{count} instances")
    end

    def scatter(message)
      LOGGER.info("Sending message to all registered workers")
    end

  end
end
