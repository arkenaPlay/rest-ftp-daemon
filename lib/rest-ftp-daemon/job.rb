require 'net/ftp'


module RestFtpDaemon
  class Job < RestFtpDaemon::Common

    def initialize(id, params={})
      # Call super
      super()

      # Grab params
      @params = params
      @target = nil
      @source = nil

      # Init context
      set :id, id
      set :started_at, Time.now
      set :status, :created

      # Send first notification
      notify "rftpd.queued"
    end

    def progname
      job_id = get(:id)
      "JOB #{job_id}"
    end

    def id
      get :id
    end

    def priority
      get :priority
    end
    def get_status
      get :status
    end

    def process
      # Init
      info "Job.process starting"
      set :status, :starting
      set :error, 0

      begin
        # Validate job and params
        prepare

        # Process
        transfer

      rescue Net::FTPPermError => exception
        info "Job.process failed [Net::FTPPermError]"
        set :status, :failed
        set :error, exception.class

      rescue RestFtpDaemonException => exception
        info "Job.process failed [RestFtpDaemonException::#{exception.class}]"
        set :status, :failed
        set :error, exception.class

      # rescue Exception => exception
      #   set :status, :crashed
      #   set :error, exception.class

      else
        info "Job.process finished"
# set :error, 0
        #set :status, :wandering

        # Wait for a few seconds before marking the job as finished
        # info "#{prefix} wander for #{RestFtpDaemon::THREAD_SLEEP_BEFORE_DIE} sec"
        # wander RestFtpDaemon::THREAD_SLEEP_BEFORE_DIE
        set :status, :finished
      end

    end

    def describe
      # Update realtime info
      w = wandering_time
      set :wandering, w.round(2) unless w.nil?

      # Update realtime info
      u = up_time
      set :uptime, u.round(2) unless u.nil?

      # Return the whole structure
      @params
    end

    def status text
      @status = text
    end

    def get attribute
      return nil unless @params.is_a? Enumerable
      @params[attribute.to_s]
    end

  protected

    def up_time
      return if @params[:started_at].nil?
      Time.now - @params[:started_at]
    end

    def wander time
      info "Job.wander #{time}"
      @wander_for = time
      @wander_started = Time.now
      sleep time
      info "Job.wandered ok"
    end

    def wandering_time
      return if @wander_started.nil? || @wander_for.nil?
      @wander_for.to_f - (Time.now - @wander_started)
    end

    # def exception_handler(actor, reason)
    #   set :status, :crashed
    #   set :error, reason
    # end

    def set attribute, value
      return unless @params.is_a? Enumerable
      @params[:updated_at] = Time.now
      @params[attribute.to_s] = value
    end

    def expand_path_from path
      File.expand_path replace_token_in_path(path)
    end

    def expand_url_from path
      URI replace_token_in_path(path) rescue nil
    end

    def replace_token_in_path path
      # Ensure endpoints are not a nil value
      return path unless Settings.endpoints.is_a? Enumerable
      newpath = path.clone

      # Replace endpoints defined in config
      Settings.endpoints.each do |from, to|
        newpath.gsub! "[#{from}]", to
      end

      # Replace with the special RAND token
      newpath.gsub! "[RANDOM]", SecureRandom.hex(8)

      return newpath
    end

    def prepare
      # Init
      set :status, :preparing

      # Check source
      raise JobSourceMissing unless @params["source"]
      @source = expand_path_from @params["source"]
      set :debug_source, @source

      # Check target
      raise JobTargetMissing unless @params["target"]
      @target = expand_url_from @params["target"]
      set :debug_target, @target.inspect

      # Check compliance
      raise JobTargetUnparseable if @target.nil?
      raise JobSourceNotFound unless File.exists? @source

    end

    def transfer_fake
      # Init
      set :status, :faking

      # Work
      (0..9).each do |i|
        set :faking, i
        sleep 0.5
      end
    end

    def transfer
      # Send first notification
      transferred = 0
      notify "rftpd.started"

      # Ensure @source and @target are there
      set :status, :checking_source
      raise JobPrerequisitesNotMet unless @source
      raise JobPrerequisitesNotMet unless @source
      target_path = File.dirname @target.path
      target_name = File.basename @target.path

      # Read source file size
      source_size = File.size @source
      set :file_size, source_size

      # Prepare FTP transfer
      set :status, :connecting
      ftp = Net::FTP.new(@target.host)
      ftp.passive = true
      ftp.login @target.user, @target.password

      # Changind directory
      set :status, :chdir
      ftp.chdir(target_path)

      # Check for target file presence
      if get(:overwrite).nil?
        set :status, :target_checking
        results = ftp.list(target_name)
        #results = ftp.list()

        unless results.count.zero?
          set :status, :target_found
          ftp.close
          notify "rftpd.ended", RestFtpDaemon::JobTargetFileExists
          raise RestFtpDaemon::JobTargetFileExists
        end

        set :status, :target_available
      end

      # Do transfer
      set :status, :uploading
      chunk_size = Settings.transfer.chunk_size || Settings[:app_chunk_size]
      ftp.putbinaryfile(@source, target_name, chunk_size) do |block|
        # Update counters
        transferred += block.bytesize

        # Update job info
        percent = (100.0 * transferred / source_size).round(1)
        set :progress, percent
        set :file_sent, transferred
      end

      # Close FTP connexion
      notify "rftpd.ended"
      set :progress, nil
      ftp.close
    end

  private

  end
end
