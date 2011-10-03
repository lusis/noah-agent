require 'redis'
module NoahAgent
  class Redis
    include Celluloid

    def initialize(host,port)
      LOGGER.debug("Redis - Initializing Redis connection")
      @r = ::Redis.connect :host => host, :port => port
      self.watch!
    end

    def watch
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
    end

  end
end
