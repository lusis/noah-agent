require 'logger'
NoahAgent::LOGGER = Logger.new(STDOUT)
NoahAgent::LOGGER.progname = "noah-agent"
Celluloid.logger = NoahAgent::LOGGER
