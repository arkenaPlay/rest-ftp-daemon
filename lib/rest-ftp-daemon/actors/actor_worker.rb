module RestFtpDaemon
  class ActorWorker
    include Celluloid
    include Celluloid::Logger

    def initialize name
      info  "ActorWorker.initialize"

      #self.async.main
      #main
      # sleep 1

      # Self ID
      @id = gen_worker_id

      self.async.main
    end

    def main
      info  "ActorWorker[#{@id}].main"

      loop do
        info "ActorWorker[#{@id}].main: tick"

        if rand(5)==0
          info "ActorWorker[#{@id}].main: let's crash !"
          raise StandardError
        else
          sleep 1
        end
      end
    end

    def ping
      puts "pong"
    end

    protected

    def gen_worker_id
      Digest::SHA1.hexdigest(UUID.generate)
    end

  end
end
