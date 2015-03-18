# Load gem files
load_path_libs = File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(load_path_libs) unless $LOAD_PATH.include?(load_path_libs)
require 'rest-ftp-daemon'

# Create queue and worker pool
$queue = RestFtpDaemon::JobQueue.new
$pool = RestFtpDaemon::WorkerPool.new(Settings.workers || APP_WORKERS)

# Rack reloader
unless Settings.namespace == "production"
  use Rack::Reloader, 0
end

# Rack authent
unless Settings.adminpwd.nil?
  use Rack::Auth::Basic, "Restricted Area" do |username, password|
    [username, password] == ['admin', Settings.adminpwd]
  end
end

# Serve static assets
use Rack::Static, :urls => ["/css", "/images"], :root => "#{APP_LIBS}/static/"
# Faye pub/sub
use Faye::RackAdapter, :mount => '/push', :timeout => 10, :ping => 10 do |server|
  server.on(:handshake) do |client_id|
    puts "faye handshake: #{client_id}"
  end
end

# Launch the main daemon
run RestFtpDaemon::API::Root
#run Rack::Cascade.new [RestFtpDaemon::API::Root]
