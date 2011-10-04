#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")))
require 'rubygems'
require 'slop'
require 'json'

require 'noah-agent'

module NoahAgent
  class Cli
    include Celluloid
    trap_exit :actor_died

    def initialize
      NoahAgent::LOGGER.info("Starting up noah-agent")
      @redis = NoahAgent::Redis.supervise_as :redis, "127.0.0.1", 6379
      @noah = NoahAgent::WatchList.supervise_as :watchlist, "http://127.0.0.1:5678"
      @broker = NoahAgent::Broker.supervise_as :broker, "broker"
    end

    def startup
      @redis.actor.watch!
      @noah.actor.get_watchlist
      @broker.actor.register_plugin!(NoahAgent::Http)
      @broker.actor.register_plugin!(NoahAgent::Dummy)
    end

    def actor_died(actor, reason)
      NoahAgent::LOGGER.fatal("#{actor.inspect}: #{reason}")
    end
  end
end

cli = NoahAgent::Cli.new
cli.startup

trap("INT") { NoahAgent::LOGGER.debug("Shutting down. Watches will not be fired");exit }

while true do
  sleep 5
end
