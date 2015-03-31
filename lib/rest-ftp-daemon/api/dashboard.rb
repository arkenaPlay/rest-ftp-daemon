module RestFtpDaemon
  module API
    class Root < Grape::API


####### HELPERS

      helpers do
      end


####### DASHBOARD - GET /

      # Server global status
      get '/' do

        report = MemoryProfiler.report do

        info "GET /"

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
        env['api.format'] = :html
        format "html"
        status 200
        content_type "text/html"

        body output

        end

        filename = LOG_DUMPS + "report-dashboard-#{Time.now.to_s}.txt"
        io = File.open(filename, 'w')
        report.pretty_print(io)
      end

    end
  end
end
