require './lib/noah-agent'

class FooWorker
  include NoahAgent::Worker
  ENDPOINT_PATTERN = "fooworker://"

  def work(e,m)
   # Define how to handle your work
    puts "Endpoint: #{e}. Message #{m}"
  end
end

@redis = NoahAgent::Redis.supervise_as :redis, "127.0.0.1", 6379
@broker = NoahAgent::Broker.supervise_as :broker, "noah_broker"
@watcher = NoahAgent::WatchList.supervise_as :watchlist, "http://127.0.0.1:5678"

#NoahAgent::Pool.supervise_as :dummy_pool, "dummy_pool", {:num_workers => 10 , :worker_class => NoahAgent::Dummy}
#NoahAgent::Pool.supervise_as :http_pool, "http_pool", {:num_workers => 10 , :worker_class => NoahAgent::Http}

#@dp = Celluloid::Actor[:dummy_pool]
#@hp = Celluloid::Actor[:http_pool]
#500.times { @dp.notify_worker! "dummy://foobar", '{"status":"up"}' }

#while true do
#  puts "#{@dp.available_workers.size}|#{@dp.busy_workers.size}|#{@dp.backlog.size}"
#  sleep 5
#end
