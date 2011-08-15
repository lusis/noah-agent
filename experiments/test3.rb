#!/usr/bin/env ruby
require 'celluloid'
require 'logger'
require 'uuid'
require 'sinatra/base'

# This is just a simple demo of a possible Pool implementation for Celluloid
# The sinatra interface exists just to do some testing of crashing workers and the like

# TODO
# Create a busy worker registry of some kind
# Implement a small stats page

LOGGER = Logger.new('worker.log')
LOGGER.progname = __FILE__
Celluloid.logger = LOGGER

class WorkerError < Exception; end

class Pool
  include Celluloid::Actor
  #trap_exit :worker_exception_handler

  attr_reader :workers, :busy_workers

  def initialize(name, opts = {:num_workers => 10, :worker_class => Worker})
    @name = name
    @workers = []
    @busy_workers = []
    LOGGER.info("Pool #{name} starting up")
    opts[:num_workers].times do |worker|
      start_worker(opts[:worker_class])
    end
  end

  def start_worker(klass)
    worker_id = gen_worker_id
    LOGGER.info("Pool #{@name} is starting a #{klass.to_s} worker")
    wkr = klass.supervise_as "#{@name}_worker_#{worker_id}".to_sym, "#{@name}_worker_#{worker_id}"
    @workers << wkr
  end

  def notify_worker(msg)
    if @workers.size == @busy_workers.size
      LOGGER.info "All workers busy. You must construct additional pylons!"
    else
      worker = self.get_worker
      @busy_workers << worker.name
      worker.work msg
      @busy_workers.delete worker.name
      LOGGER.info("Worker #{worker.name} finished working")
    end
  end

  def worker_exception_handler(actor, reason)
    LOGGER.debug("Worker #{actor.name} crashed because #{reason}. You should see a doctor about that")
  end

  
  protected
  def gen_worker_id
    Digest::SHA1.hexdigest(UUID.generate)
  end

  def get_worker
    worker = @workers.sample.actor
    LOGGER.info("Found Worker: #{worker.name} in the pool. Checking eligibility.")
    if @busy_workers.member? "#{worker.name}"
      LOGGER.info "Worker #{worker.name} was busy. Retrying!"
      self.get_worker
    end
    if worker.alive?
      worker
    else
      LOGGER.info "Worker #{worker.name} was dead. Retrying!"
      self.get_worker
    end
  end

end

class MyWorker
  include Celluloid::Actor
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def work(msg)
    LOGGER.info("Message for you sir! #{msg}")
    case msg
    when "die"
      # Simulate some long-running work that crashes
      sleep 15
      raise WorkerError, "Boo got shot!"
    else
      # Simulate some long-running work here
      sleep 30
      LOGGER.debug("Hey there camper! #{@name} is doing some work for you")
    end
  end

end

class TestApp < Sinatra::Base
  @pool = Pool.supervise_as :my_cool_pool, "MyCoolPool", {:num_workers => 30, :worker_class => MyWorker}
  configure do
    set :app_file, __FILE__
    set :logging, false
    set :dump_errors, false
    set :run, false
    #set :server, "thin"
    set :pool, @pool
  end

  put '/scale' do
    settings.pool.actor.start_worker(MyWorker)
    "Added a worker"
  end

  get '/stats' do
    "Worker count: #{settings.pool.actor.workers.size}\n Busy workers: #{settings.pool.actor.busy_workers.size}"
  end

  put '/die' do
    settings.pool.actor.notify_worker! "die"
  end

  put '/send' do
    settings.pool.actor.notify_worker! request.body.read
  end
end

app = TestApp
app.run!
