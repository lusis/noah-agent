require './lib/noah-agent'

@redis = Noah::Agent::Redis.supervise_as :redis, "127.0.0.1", 6379
@broker = Noah::Agent::Broker.supervise_as :broker, "noah_broker"
@watcher = Noah::Agent::WatchList.supervise_as :watchlist, "http://localhost:5678"


