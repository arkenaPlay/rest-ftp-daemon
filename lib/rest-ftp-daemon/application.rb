# trap 'INT' do
#   RestFtpDaemon::Application.shutdown
# end

# trap 'TERM' do
#   RestFtpDaemon::Application.shutdown
# end

require "celluloid"
require_relative "celluloid_init"

module RestFtpDaemon
  module Application
    class << self
      include Celluloid::Logger

      #supervise RestFtpDaemon::ActorDebug, as: :actor_debug, args: ["bruno"]
      # supervise RestFtpDaemon::ActorAPI, as: :actor_api, args: ["bruno"]
      #pool RestFtpDaemon::ActorWorker, as: :actor_worker, args: ["bruno"], size: 2

      def run(options = {})

        # Create global queue
        $queue = RestFtpDaemon::JobQueue.new

        # Initialize workers and conchita subsystem
        $pool = RestFtpDaemon::WorkerPool.new

        loop do
          registry = Celluloid::Registry.new
          supervisor = RestFtpDaemon::Supervisor.new(registry, options)
          #supervisor[:actor_debug].async(:main) # if options[:eager_build]
          #supervisor = run!(options)

          while supervisor.alive?
            info "RestFtpDaemon::Application.main: tick"
            sleep 1
            # sleep 0.1
            if @shutdown
              info  "Application: shutdown!"
              supervisor.terminate
              info  "Application: terminated"
            end
          end

          break if @shutdown
          log.error "!!! #{self} crashed. Restarting..."
        end
      end

      def shutdown
        @shutdown = true
      end

    end
  end
end
