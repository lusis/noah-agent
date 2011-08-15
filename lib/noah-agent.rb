module Noah
  module Agent
    require 'celluloid'
    require File.join(File.dirname(__FILE__), 'noah-agent', 'watchlist')
    require File.join(File.dirname(__FILE__), 'noah-agent', 'redis')
    require File.join(File.dirname(__FILE__), 'noah-agent', 'logging')
    require File.join(File.dirname(__FILE__), 'noah-agent', 'worker')
    require File.join(File.dirname(__FILE__), 'noah-agent', 'pool')
    require File.join(File.dirname(__FILE__), 'noah-agent', 'broker')
  end
end
