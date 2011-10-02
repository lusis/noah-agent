module NoahAgent
  module Worker
    ENDPOINT_PATTERN = "nil://"

    def self.included(base)
      base.send :include, Celluloid
      base.send :attr_reader, :name

      def initialize(name, pool_name)
        @name = name
        @pool_name = pool_name
      end

      protected
      def notify(e,m)
        begin
          self.work(e,m)
        rescue NoMethodError
          LOGGER.warn("You haven't defined how I should 'work'")
        rescue Exception => e
          LOGGER.fatal("Unknown exception in worker: #{e.message}")
        end
        Celluloid::Actor[@pool_name.to_sym].free_worker(@name)
      end
    end
  end
end
