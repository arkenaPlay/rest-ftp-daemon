module RestFtpDaemon

  # Worker used to process Jobs
  class JobWorker < Worker

    def initialize wid
      # Generic worker initialize
      super

      # Timeout config
      @timeout = (Settings.transfer.timeout rescue nil) || DEFAULT_WORKER_TIMEOUT

      # Start main loop
      log_info "JobWorker starting", ["timeout: #{@timeout}"]
      start
    end

  protected

    def work
      # Wait for a job to be available in the queue
      worker_status WORKER_STATUS_WAITING
      job = $queue.pop

      # Work on this job
      work_on_job(job)

      # Clean job status and sleep for 1s
      job.wid = nil
      sleep 1

      # If job status requires a retry, just restack it
      on_errors = Settings.at(:retry, :on_errors)
      max_age = Settings.at(:retry, :max_age)
      max_runs = Settings.at(:retry, :max_runs)
      delay = Settings.at(:retry, :delay)

      if !job.error
        #log_info "job succeeded"

      elsif !(on_errors.is_a?(Enumerable) && on_errors.include?(job.error))
        log_error "not retrying: error not eligible"

      elsif max_age && (job.age >= max_age)
        log_error "not retrying: max_age reached (#{max_age} s)"

      elsif max_runs && (job.runs >= max_runs)
        log_error "not retrying: max_runs reached (#{max_runs} tries)"

      else
        # Delay cannot be negative, and will be 1s minimum
        retry_after = [delay || DEFAULT_RETRY_DELAY, 1].max
        log_info "retrying job: waiting for #{retry_after} seconds"

        # Wait !
        sleep retry_after
        log_info "retrying job: requeued after delay"

        # Now, requeue this job
        $queue.requeue job
      end

      # Clean worker status
      worker_jid nil

    rescue StandardError => ex
      log_error "WORKER UNHANDLED EXCEPTION: #{ex.message}", ex.backtrace
      worker_status WORKER_STATUS_CRASHED
    end

    def work_on_job job
      # Prepare job and worker for processing
      worker_status WORKER_STATUS_RUNNING, job
      worker_jid job.id
      job.wid = Thread.current.thread_variable_get :wid

      # Processs this job protected by a timeout
      Timeout.timeout(@timeout, RestFtpDaemon::JobTimeout) do
        job.process
      end

      # Processing done
      worker_status WORKER_STATUS_FINISHED, job

      # Increment total processed jobs count
      $queue.counter_inc :jobs_processed

    rescue RestFtpDaemon::JobTimeout => ex
      log_error "JOB TIMED OUT", ex.backtrace
      worker_status WORKER_STATUS_TIMEOUT

      # Inform the job
      job.oops_you_stop_now ex unless job.nil?

    rescue StandardError => ex
      log_error "JOB UNHANDLED EXCEPTION ex[#{ex.class}] #{ex.message}", ex.backtrace
      worker_status WORKER_STATUS_CRASHED

      # Inform the job
      job.oops_after_crash ex unless job.nil?
    end

    if Settings.newrelic_enabled?
      add_transaction_tracer :work,       category: :task
    end

  end
end
