module RestFtpDaemon
  class ActorDebug
    include Celluloid
    include Celluloid::Logger

    def initialize name
      info  "ActorDebug.initialize"

      #self.async.main
      #main
      # sleep 1
      self.async.main
    end

    def main
      info  "ActorDebug.main"

      loop do
        info "ActorDebug.main: tick"
        sleep 10
      end
    end

    def ping
      puts "pong"
    end

  end
end
