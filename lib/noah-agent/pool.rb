module Noah::Agent
  class Pool
    include Celluloid::Actor
    #include Noah::Agent::Helpers
    attr_reader :workers

    def initialize(name, opts = {:num_workers => 10, :worker_class => Worker})
      @name = name
      @workers = []
      Noah::Agent::LOGGER.info("Pool #{name} starting up")
      opts[:num_workers].times do |worker|
        start_worker(opts[:worker_class])
      end
    end

    def start_worker(klass)
      worker_id = gen_worker_id
      Noah::Agent::LOGGER.info("Pool #{@name} is starting a #{klass.to_s} worker")
      @workers << (klass.supervise_as "#{@name}_worker_#{worker_id}".to_sym, "#{@name}_worker_#{worker_id}")
    end

    def notify_worker(msg)
      worker = self.get_worker
      worker.work msg
    end

    protected
    def gen_worker_id
      Digest::SHA1.hexdigest(UUID.generate)
    end

    def get_worker
      worker = @workers.sample.actor
      Noah::Agent::LOGGER.info("Found Worker: #{worker.name} in the pool")
      self.get_worker if worker.busy?
      if worker.alive?
        worker
      else
        Noah::Agent::LOGGER.error "Worker #{worker.name} was dead. Retrying!"
        self.get_worker
      end
    end

  end
end
