require 'redis'
module NoahAgent
  class Redis
    include Celluloid

    def initialize(host,port)
      LOGGER.debug("Redis - Starting up")
      @r = ::Redis.connect :host => host, :port => port
      self.watch!
    end

    def watch
      begin
        NoahAgent::LOGGER.info("Redis - Attempting connection to Redis")
        @r.psubscribe("*") do |on|
          on.pmessage do |pattern, event, message|
            LOGGER.info("Redis - Message recieved")
            LOGGER.debug("Redis - Message contents: #{message}")
            if event =~ /^\/\/noah\/watchers\/.*/
              Celluloid::Actor[:watchlist].reread_watchers(message)
            else
              LOGGER.info("#{pattern} - #{event} - #{message}")
              Celluloid::Actor[:broker].handle(event, message)
            end
          end
        end
      rescue Exception => e
        NoahAgent::LOGGER.debug("Redis connection failed with: #{e.message}")
        NoahAgent::LOGGER.debug("Attempting to reconnect in 10 seconds")
        sleep 10
        retry
      end
    end

  end
end
