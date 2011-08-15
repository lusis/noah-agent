require 'redis'
module Noah::Agent
  class Redis
    include Celluloid::Actor

    def initialize(host,port)
      LOGGER.debug("Initializing Redis Actor")
      @r = ::Redis.connect :host => host, :port => port
    end

    def watch
      @r.psubscribe("*") do |on|
        on.pmessage do |pattern, event, message|
          LOGGER.info("Message recieved")
          LOGGER.debug("Message contents: #{message}")
          if event =~ /^\/\/noah\/watchers\/.*/
            Celluloid::Actor[:watchlist_manager].reread_watchers(message)
          else
            LOGGER.info("#{pattern} - #{event} - #{message}")
            #Celluloid::Actor[:broker_manager].handle(message)
          end
        end
      end
    end

  end
end
