require 'uuid'

module NoahAgent
  class Broker
    include Celluloid

    attr_reader :registered_pools, :registered_plugins

    def initialize(name)
      @name = name
      @registered_pools = Hash.new
      @registered_plugins = Array.new
      LOGGER.info("Starting broker")
    end

    def register_plugin(plugin_name)
      LOGGER.info("Registering new plugin: #{plugin_name}")
      unless @registered_plugins.member?(plugin_name)
        @registered_plugins << plugin_name
        self.start_pool!(plugin_name)
      end
    end

    def start_pool(klass)
      pool_pattern = URI.parse(klass.const_get("ENDPOINT_PATTERN")+"noah").scheme
      opts = {:worker_class => klass, :num_workers => 10}
      LOGGER.info("Starting pool #{klass.to_s}")
      Pool.supervise_as "pool_#{pool_pattern}".to_sym, "pool_#{pool_pattern}", opts
      @registered_pools.merge!({pool_pattern => "pool_#{pool_pattern}"})
    end

    def handle(pattern, msg)
      LOGGER.info("Broker - Message recieved for brokering")
      LOGGER.debug("Broker - Pattern: #{pattern}| Message: #{msg}")
      process_message(pattern, msg)
    end

    private
    def process_message(pattern, msg)
      Celluloid::Actor[:watchlist].watchlist.select do |id, details|
        if pattern =~ /^#{details[:pattern]}/ 
          LOGGER.info("Broker - Found match for #{pattern} - #{details[:endpoint]}")
          ep = details[:endpoint]
          pool = "pool_#{URI.parse(ep).scheme}"
          Celluloid::Actor[pool.to_sym].notify_worker!(ep, msg)
        end
      end
    end

    def find_plugins
    end

  end
end
