require 'thread'
require 'securerandom'

module RestFtpDaemon
  class JobQueue < Queue
    # attr_reader :queued
    # attr_reader :popped

    attr_reader :queue
    attr_reader :jobs

    def initialize
      # Instance variables
      @queue = []
      @jobs = []
      @waiting = []
      @queue.taint          # enable tainted communication
      @waiting.taint
      self.taint
      @mutex = Mutex.new

      # Logger
      @logger = RestFtpDaemon::LoggerPool.instance.get :queue

      # Identifiers generator
      @last_id = 0
      @prefix = Helpers.identifier JOB_IDENT_LEN
      info "queue initialized with prefix: #{@prefix}"

      # Mutex for counters
      @counters = {}
      @mutex_counters = Mutex.new

      # Conchita configuration
      @conchita = Settings.conchita
      if @conchita.nil?
        info "conchita: missing conchita.* configuration"
      elsif @conchita[:timer].nil?
        info "conchita: missing conchita.timer value"
      else
        Thread.new {
          begin
            conchita_loop
          rescue Exception => e
            info "CONCHITA EXCEPTION: #{e.inspect}"
          end
          }
      end

    end

    def generate_id
      rand(36**8).to_s(36)
      @last_id ||= 0
      @last_id += 1
      prefixed_id @last_id
    end

    def counter_add name, value
      @mutex_counters.synchronize do
        @counters[name] ||= 0
        @counters[name] += value
      end
    end

    def counter_inc name
      counter_add name, 1
    end

    def counter_get name
      @mutex_counters.synchronize do
        @counters[name]
      end
    end

    def counters
      @mutex_counters.synchronize do
        @counters
      end
    end

    def sorted_by_status status
      # Just use the base if filter is empty
      if status.empty?
        elements = all
      else
        elements = all.select { |item| item.status == status.to_sym }
      end

      # Sort these elements
      elements.sort_by do |item|
        w = JOB_WEIGHTS[item.status] || 0
        [ w,  item.wid.to_s, item.updated_at.to_s]
      end

    end

    def counts_by_status
      statuses = {}
      @jobs.group_by { |job| job.status }.map { |status, jobs| statuses[status] = jobs.size }
      statuses
    end

    def jobs # change for accessor
      @jobs
    end

    def jobs_size
      @jobs.length
    end

    def find_by_id id, prefixed = false
      # Build a prefixed id if expected
      id = prefixed_id(id) if prefixed
      info "find_by_id (#{id}, #{prefixed}) > #{id}"

      # Search in both queues
      @queued.select { |item| item.id == id }.last || @popped.select { |item| item.id == id }.last
    end

    def push job
      # Check that item responds to "priorty" method
      raise "JobQueue.push: job should respond to priority method" unless job.respond_to? :priority
      raise "JobQueue.push: job should respond to id method" unless job.respond_to? :id

      @mutex.synchronize do
        # Push job into the queue
        @queue.push job

        # Store the job into the global jobs list
        @jobs.push job

        # Inform the job that it's been queued
        job.set_queued if job.respond_to? :set_queued

        # Refresh queue order
        sort_queue!

        # Try to wake a worker up
        begin
          t = @waiting.shift
          t.wakeup if t
        rescue ThreadError
          retry
        end
      end
    end
    alias << push
    alias enq push

    def pop(non_block=false)
      # info "JobQueue.pop"
      @mutex.synchronize do
        while true
          if @queue.empty?
            # info "JobQueue.pop: empty"
            raise ThreadError, "queue empty" if non_block
            @waiting.push Thread.current
            @mutex.sleep
          else
            # info "JobQueue.pop: great, I'm not empty!!"
            return pick_one
          end
        end
      end
    end
    alias shift pop
    alias deq pop

    def empty?
      @queue.empty?
    end

    def clear
      @queue.clear
    end

    def num_waiting
      @waiting.size
    end

  protected

    def prefixed_id id
      "#{@prefix}.#{id}"
    end

    def sort_queue!
      @mutex_counters.synchronize do
        @queue.sort_by! &:weight
      end
    end

    def conchita_loop
      info "conchita starting with: #{@conchita.inspect}"
      loop do
        # Do the cleanup
        conchita_clean JOB_STATUS_FINISHED
        conchita_clean JOB_STATUS_FAILED
        sleep @conchita[:timer]
      end
    end

    def conchita_clean status
      # Init
      return if status.nil?
      key = "clean_#{status.to_s}"

      # Read config state
      max_age = @conchita[key.to_s]
      return if [nil, false].include? max_age

      # Delete jobs from the queue if their status is (status)
      @jobs.delete_if do |job|
        # Skip it if wrong status
        next unless job.status == status.to_sym

        # Skip it if updated_at invalid
        updated_at = job.updated_at
        next if updated_at.nil?

        # Skip it if not aged enough yet
        age = Time.now - updated_at
        next if age < max_age

        # Ok, we have to clean it up ..
        info "conchita_clean #{status.inspect} max_age:#{max_age} job:#{job.id} age:#{age}"
        true
      end

    end

  private

    def info message, context = {}
      return if @logger.nil?

      # Inject context
      context[:origin] = self.class

      # Forward to logger
      @logger.info_with_id message, context
    end

  end
end
