module RestFtpDaemon
  class Supervisor < Celluloid::SupervisionGroup
    include Celluloid::Logger

    #supervise RestFtpDaemon::ActorAPI, as: :actor_api, args: ["bruno"]

    def initialize(registry, options = {})
      super(registry)
      #info "Supervisor.initialize"

      #supervise_as :actor_debug, RestFtpDaemon::ActorDebug, args: ["bruno"]
      # supervise_as :actor_api, RestFtpDaemon::ActorReelAPI, args: ["bruno"]
      # supervise_as :actor_api, RestFtpDaemon::ActorAPI
      #pool RestFtpDaemon::ActorWorker, as: :actor_worker, args: ["bruno"], size: 2

    end

  end
end
