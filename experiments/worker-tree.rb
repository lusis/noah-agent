require 'rubygems'
require 'celluloid'
require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.progname = __FILE__
Celluloid.logger = LOGGER

class Broker
  include Celluloid::Actor

  def initialize
    LOGGER.info "Starting up pool_a"
    pool_a = AWorkerPool.supervise_as :pool_a, "Pool A"
  end

  def a_message(msg)
    LOGGER.info "Sending message to pool_a"
    Celluloid::Actor[:pool_a].notify msg
  end

end

class AWorker
  include Celluloid::Actor
  trap_exit :worker_died
  class WorkerError < StandardError; end

  attr_reader :name
  def initialize(name)
    @name = name
    LOGGER.info "Starting agent - #{@name}"
  end

  def do_work(msg)
    case msg
    when "die!"
      raise WorkerError, "#{@name} was murdered"
    else
      LOGGER.info "#{@name} is working"
      sleep 10
      LOGGER.info "#{@name} is done working"
    end
  end

  def worker_died(actor, reason)
    LOGGER.warn "Some other guy died"
  end
end

class AWorkerPool
  include Celluloid::Actor
  trap_exit :worker_died
  MAX_WORKERS = 10
  attr_reader :all_workers, :name

  def initialize(name)
    @name = name
    @all_workers = []
    LOGGER.info "AWorkerPool starting up"
    MAX_WORKERS.times do |iter|
      start_worker(iter)
    end
  end

  def start_worker(id)
    LOGGER.info "Starting up worker a_worker_#{id}"
    @all_workers[id] = AWorker.supervise_as "pool_A_worker_#{id}".to_sym, "pool_A_worker_#{id}"
  end

  def notify(msg)
    worker = @all_workers.sample.actor
    if worker.busy?
      LOGGER.warn "Worker #{worker.name} was busy. Retrying"
      notify! msg
    end

    if worker.alive?
      LOGGER.info "Send message: #{msg} to selected worker from pool: #{worker.name}"
      worker.do_work! msg
    else
      LOGGER.error "Worker #{worker.inspect} was dead. Retrying"
      self.notify! msg
    end
  end

  def worker_died(actor, reason)
    puts "#{actor.name} died because of #{reason.class}"
  end

end

puts "Starting up broker"
b = Broker.supervise
@broker = b.actor
@broker.a_message! "Do some work"
AWorkerPool::MAX_WORKERS.times do |x|
  LOGGER.warn "Selecting a random worker to kill!"
  @broker.a_message! "die!"
  @broker.a_message! "more work"
  sleep 5
end
puts "Finished wreaking havock"
