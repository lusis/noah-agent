module Noah::Agent
  class Broker
    include Celluloid::Actor
    attr_reader :registered_pools

    def initialize(name)
      @name = name
      Noah::Agent::LOGGER.info("Starting broker actor")
    end

    def start_pool(klass)
      pool_string = klass.to_s.gsub(/::/, '_')
      Noah::Agent::LOGGER.info("Starting pool #{klass.to_s}")
      klass.supervise_as "pool_#{pool_string}".to_sym, "pool_#{pool_string}"
    end

    def handle(msg)

    end

  end
end
