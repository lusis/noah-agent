require 'uuid'

module NoahAgent
  class Broker
    include Celluloid
    attr_reader :registered_pools

    def initialize(name)
      @name = name
      LOGGER.info("Starting broker actor")
    end

    def start_pool(klass)
      pool_string = klass.to_s.gsub(/::/, '_')
      LOGGER.info("Starting pool #{klass.to_s}")
      Pool.supervise_as "pool_#{pool_string}".to_sym, "pool_#{pool_string}", klass
    end

    def handle(pattern, msg)
      LOGGER.info("Message recieved for brokering")
      LOGGER.debug("Pattern: #{pattern}| Message: #{msg}")
    end

  end
end
