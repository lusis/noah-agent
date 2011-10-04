require 'excon'
require 'multi_json'
module NoahAgent
  class WatchList
    include Celluloid
    attr_reader :watchlist

    def initialize(noah_url)
      LOGGER.info("Starting watchlist")
      @noah_url = noah_url
      @watchlist ||= {}
      self.get_watchlist!
    end

    def get_watchlist
      LOGGER.info("Loading watchlist from Noah")
      begin
        noah = Excon.get(@noah_url+"/watches")
      rescue Exception => e
        NoahAgent::LOGGER.debug("Failed to get watches: #{e.message}")
        NoahAgent::LOGGER.debug("Retrying in 10 seconds")
        sleep 10
        retry
      end
      case noah.status
      when 404
        LOGGER.warn("Noah returned 404. Assuming empty watchlist")
      when 500
        data = MultiJson.decode(noah.body)
        LOGGER.fatal("Noah returned 500. This could be bad")
        LOGGER.debug("Noah error: #{data["error_message"]}")
      when 200
        data = MultiJson.decode(noah.body)
        load_initial_watchers(data)
        LOGGER.info("Starting up with #{@watchlist.keys.size} watchers")
        LOGGER.debug("#{@watchlist.keys}")
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
      LOGGER.info("New watch list size: #{@watchlist.keys.size}")
      LOGGER.debug("Current watchlist: #{@watchlist.keys}")
    end

    private
    def load_initial_watchers(watch_list)
      LOGGER.debug("Parsing initial watch list")
      watch_list.each do |watch|
        @watchlist.merge! parse_watch(watch)
        LOGGER.debug(@watchlist)
      end
    end

    def parse_watch(watch)
      LOGGER.info("Parsing watch: #{watch["id"]}")
      LOGGER.debug("Watch contents: #{watch}")
      {watch["id"] => {:pattern => watch["pattern"], :endpoint => watch["endpoint"]}}
    end
  end
end
