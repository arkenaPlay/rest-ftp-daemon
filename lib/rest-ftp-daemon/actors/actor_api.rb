require 'rack'
require 'thin'
# Lots of this file are inspired from https://github.com/berkshelf/berkshelf-api

module RestFtpDaemon
  class ActorAPI
    include Celluloid
    include Celluloid::Logger

    def initialize #options = {}
      info  "ActorAPI.initialize"
      #super options

      options = {
        Port: 3005
      }

      start_thin options
      # app = Thin::Runner.new("").run!
    end

  private

    def start_thin options
      info  "ActorAPI.start_thin"

      # Build the full rack stack and run it through Thin
      Rack::Handler::Thin.run(rack_stack, options)
    end

    def rack_stack
      Rack::Builder.new do
        use Rack::Static, :urls => ["/css", "/images"], :root => "#{APP_LIBS}/static/"
        run RestFtpDaemon::API::Root
      end
    end

  end
end
