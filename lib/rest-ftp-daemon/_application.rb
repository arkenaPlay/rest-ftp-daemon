# trap 'INT' do
#   RestFtpDaemon::Application.shutdown
# end

# trap 'TERM' do
#   RestFtpDaemon::Application.shutdown
# end

module RestFtpDaemon
  class Application < Celluloid::SupervisionGroup
    include Celluloid::Logger

    #supervise RestFtpDaemon::ActorAPI, as: :actor_api, args: ["bruno"]
    #pool RestFtpDaemon::ActorWorker, as: :actor_worker, args: ["bruno"], size: 2


    def initialize(registry, options = {})
      super(registry)

      info "Application.initialize"
      #super

      supervise_as :actor_debug, RestFtpDaemon::ActorDebug, args: ["bruno"]

      @shutdown = false

      #self[:actor_debug].main

      # (registry, options = {})
      # super(registry)
      #supervise_as(:cache_manager, Berkshelf::API::CacheManager)
      #supervise_as(:cache_builder, Berkshelf::API::CacheBuilder)

      #supervise_as(:cache_builder, RestFtpDaemon::CacheBuilder)

      # unless options[:disable_http]
      #   require_relative 'rest_gateway'
      #   supervise_as(:rest_gateway, Berkshelf::API::RESTGateway, options)
      # end
      #self.async.main
    end

    def run
      main
    end

    def main (options = {})
      info "Application.main"

      loop do
        info "Application.main: tick"
        sleep 1
        instance.terminate if @shutdown
      end
    end

    # def shutdown
    #   info "Application.shutdown"
    #   @shutdown = true
    # end

  end
end
