module RestFtpDaemon
  module API
    class Root < Grape::API

####### GET /debug

      get '/debug' do
        info "GET /debug"
        begin
          raise RestFtpDaemon::DummyException
        rescue RestFtpDaemon::RestFtpDaemonException => exception
          status 501
          api_error exception
        rescue Exception => exception
          status 501
          api_error exception
        else
          status 200
          {}
        end
      end

      get '/publish' do
        info "GET /publish"

        # client = Faye::Client.new('http://localhost:3100/push')

        msg = {what: "ping", caption: "ping: tout va bien"}
        #publication = $push.publish("/updates", msg)
      end

    end
  end
end
