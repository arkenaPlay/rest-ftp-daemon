
# Global libs
require "rubygems"
require "json"
require "haml"
require "uri"
require "timeout"
require "syslog"
require "net/http"
require "thread"
require "singleton"
require "newrelic_rpm"


# Development libs      /?pp=flamegraph
# unless Settings.namespace == "production"
#   require 'rack-mini-profiler'
#   # require 'stackprof'
#   require 'flamegraph'
# end

# Project's libs
require_relative "rest-ftp-daemon/constants"
require_relative "rest-ftp-daemon/settings"
require_relative "rest-ftp-daemon/exceptions"
require_relative "rest-ftp-daemon/helpers"
require_relative "rest-ftp-daemon/logger_helper"
require_relative "rest-ftp-daemon/logger_pool"
require_relative "rest-ftp-daemon/logger"
require_relative "rest-ftp-daemon/paginate"
require_relative "rest-ftp-daemon/uri"
require_relative "rest-ftp-daemon/job_queue"
require_relative "rest-ftp-daemon/worker"
require_relative "rest-ftp-daemon/worker_conchita"
require_relative "rest-ftp-daemon/worker_job"
require_relative "rest-ftp-daemon/worker_pool"
require_relative "rest-ftp-daemon/job"
require_relative "rest-ftp-daemon/notification"

require_relative "rest-ftp-daemon/path"
require_relative "rest-ftp-daemon/remote"
require_relative "rest-ftp-daemon/remote_ftp"
require_relative "rest-ftp-daemon/remote_sftp"

require_relative "rest-ftp-daemon/api/job_presenter"
require_relative "rest-ftp-daemon/api/jobs"
require_relative "rest-ftp-daemon/api/dashboard"
require_relative "rest-ftp-daemon/api/root"

# Haml monkey-patching
require_relative "rest-ftp-daemon/patch_haml"
