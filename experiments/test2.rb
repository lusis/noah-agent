require 'rubygems'
require 'celluloid'
require "logger"
require "redis"

LOGGER = Logger.new(STDOUT)
LOGGER.progname = __FILE__
Celluloid.logger = LOGGER

@watchlist = {}

class RedisWatcher
  include Celluloid::Actor

  def initialize
    LOGGER.info "Starting Redis"
    @r = Redis.connect
  end
    
  def watch
    @r.psubscribe("*") do |on|
      on.pmessage do |p, e, m|
        LOGGER.debug("Message recieved")
        case e
        when /^\/\/noah\/tags\/.*$/
          LOGGER.debug("Sending to Tags")
          Celluloid::Actor[:tags].notify!(m)
        when /^\/\/noah\/services\/.*$/
          LOGGER.debug("Sending to Services")
          Celluloid::Actor[:services].notify!(m)
        else
          LOGGER.debug("Sending to CatchAll")
          Celluloid::Actor[:catchall].notify!(m)
        end
      end
    end
  end

end

class ServicesActor
  include Celluloid::Actor

  def notify(message)
    LOGGER.info("Services got message: #{message}")
  end
end

class TagsActor
  include Celluloid::Actor

  def notify(message)
    LOGGER.info("Tags got message: #{message}")
  end
end

class CatchallActor
  include Celluloid::Actor

  def notify(message)
    LOGGER.info("Catchall got message: #{message}")
  end
end

services_supervisor = ServicesActor.supervise_as :services
tags_supervisor = TagsActor.supervise_as :tags
catchall_supervisor = CatchallActor.supervise_as :catchall
redis_supervisor = RedisWatcher.supervise_as :redis_watcher
Celluloid::Actor[:redis_watcher].watch!
LOGGER.info("Noah Watcher Agent started up")
sleep
