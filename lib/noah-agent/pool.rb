module NoahAgent
  class Pool
    include Celluloid

    attr_reader :available_workers, :busy_workers, :backlog, :max_worker_count

    def initialize(name, opts = {:num_workers => 10, :worker_class => Worker})
      @name = name
      @max_worker_count = opts[:num_workers]
      @available_workers = []
      @busy_workers = []
      @backlog = []
      LOGGER.info("Pool #{name} starting up")
      opts[:num_workers].times do |worker|
        start_worker(opts[:worker_class])
      end
    end

    def start_worker(klass)
      worker_id = gen_worker_id
      LOGGER.info("Pool #{@name} is starting a #{klass.to_s} worker")
      wkr = klass.supervise_as("#{worker_id}".to_sym, "#{worker_id}", @name)
      @available_workers << wkr.actor.name
    end

    def notify_worker(ep, msg)
      if @available_workers.size == 0
        LOGGER.warn("All workers busy. Queueing work")
        @backlog << [ep, msg]
      else
        worker = Celluloid::Actor[@available_workers.pop.to_sym]
        LOGGER::debug("Worker grabbed from pool: #{worker.name}")
        @busy_workers << worker.name
        worker.notify!(ep, msg)
        LOGGER.info("Backlog size: #{@backlog.size}. #{@busy_workers.size} workers busy. Pool status: #{@available_workers.size}/#{@max_worker_count} workers available")
      end
    end

    def free_worker(name)
      LOGGER.debug("Attempting to free up worker: #{name}")
      if @backlog.size >= 1
        LOGGER.debug("Currently #{@backlog.size} work to do. Grabbing more work")
        ep, msg = @backlog.pop
        wkr = Celluloid::Actor[name.to_sym]
        wkr.notify!(ep, msg)
      else
        LOGGER.debug("Backlog empty. Returning to pool: #{name}")
        @busy_workers.delete(name)
        @available_workers << name
      end
    end

    protected
    def gen_worker_id
      Digest::SHA1.hexdigest(UUID.generate)
    end

  end
end
