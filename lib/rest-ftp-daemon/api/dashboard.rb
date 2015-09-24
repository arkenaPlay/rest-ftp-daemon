require "grape"
require "haml"
require "sys/cpu"
require "facter"

module RestFtpDaemon
  module API
    class Dashbaord < Grape::API

####### HELPERS

      helpers do

        def logger
          Root.logger
        end

        def render name, values={}
          template = File.read("#{APP_LIBS}/views/#{name}.haml")
          haml_engine = Haml::Engine.new(template)
          haml_engine.render(binding, values)
        end

      end


####### DASHBOARD - GET /
####### Common request logging
    before do
      log_info "HTTP #{request.request_method} #{request.fullpath}", params
    end

      # Server global status
      get "/" do

        # Initialize Facter
        Facter.loadfacts

        # Detect QS filters
        @only = params["only"].to_s

        # Get jobs for this view, order jobs by their weights
        result = $queue.filter_jobs(@only).reverse

        # Provide queue only if no filtering set
        @queue = []
        @queue = $queue.queue.reverse if @only.empty?

        # Get workers status
        @worker_variables = $pool.worker_variables

        # Build paginator
        @paginate = Paginate.new result
        @paginate.only = params["only"]
        @paginate.page = params["page"]

        # Compile haml template
        output = render :dashboard

        # Send response
        env["api.format"] = :html
        format "html"
        status 200
        content_type "text/html"
        body output
      end

    end
  end
end
