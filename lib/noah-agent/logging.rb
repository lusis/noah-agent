require 'logger'
Noah::Agent::LOGGER = Logger.new(STDOUT)
Noah::Agent::LOGGER.progname = "noah-agent"
Celluloid.logger = Noah::Agent::LOGGER
