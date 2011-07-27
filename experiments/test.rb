require 'rubygems'
require 'logger'
require 'eventmachine'
require 'em-hiredis'
require 'em-http-request'
require 'multi_json'

LOGGER = Logger.new(STDOUT)
LOGGER.progname = __FILE__
@watchlist = {}

module Noah
  module Agents
    class Dummy
    
    end
  end
end

def parse_watch(watch)
  LOGGER.info("Parsing watch: #{watch["id"]}")
  LOGGER.debug("Watch contents: #{watch}")
  {watch["id"] => {:pattern => watch["pattern"], :endpoint => watch["endpoint"]}}
end

def load_initial_watchers(watch_list)
  LOGGER.debug("Parsing initial watch list")
  watch_list.each do |watch|
    @watchlist.merge! parse_watch(watch)
    LOGGER.debug(@watchlist)
  end
end

def reread_watchers(new_watch)
  LOGGER.info("Watch message found")
  w = MultiJson.decode(new_watch)
  case w["action"]
  when "delete"
    LOGGER.info("Deleting watch: #{w["id"]}")
    @watchlist.delete w["id"]
  else
    LOGGER.info("Adding new watch: #{w["id"]}")
    @watchlist.merge! parse_watch(w)
  end
  LOGGER.debug("New watch list size: #{@watchlist.keys.size}")
  LOGGER.debug("Current watchlist: #{@watchlist.keys}")
end

def broker(msg)
  LOGGER.info("#{msg}")
end

EM.run do
  EM.error_handler do |e|
    LOGGER.warn(e)
  end

  trap("INT") { LOGGER.warn("Shutting down. Watches will not be fired");EM.stop }
  h = EM::HttpRequest.new('http://localhost:5678/watches').get
  h.callback {
    case h.response_header.status
    when 404
      LOGGER.info("No registered watches found")
    when 500
      LOGGER.error("Noah returned an error: #{h.response}")
      EM.stop
    else
      LOGGER.info("Pulled list of current watches from Noah")
      w = MultiJson.decode(h.response)
      load_initial_watchers(w)
      LOGGER.info("Starting up with #{@watchlist.keys.size} watchers")
      LOGGER.debug("#{@watchlist.keys}")
    end
  }
  h.errback {
    LOGGER.error("Unable to pull the current list of watchers.")
  }
  r = EM::Hiredis.connect "redis://localhost:6379"
  r.errback {|x| LOGGER.fatal("Unable to connect to redis: #{x}");EM.stop}
  LOGGER.info("Connected to redis")
  r.psubscribe("*")
  r.on(:pmessage) do |pattern, event, message|
    LOGGER.debug("Message recieved")
    reread_watchers(message) if event =~ /^\/\/noah\/watchers\/.*/
    broker "#{event}|#{message}" unless @watchlist.keys.size == 0
  end
end
