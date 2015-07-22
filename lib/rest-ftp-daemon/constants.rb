# Terrific constants
APP_NAME = "rest-ftp-daemon"
APP_NICK = "rftpd"
APP_VER = "0.230.3"


# Jobs and workers
JOB_RANDOM_LEN          = 8
JOB_IDENT_LEN           = 4
JOB_TEMPFILE_LEN        = 8
JOB_UPDATE_INTERVAL     = 1

JOB_STATUS_UPLOADING    = :uploading
JOB_STATUS_RENAMING     = :renaming
JOB_STATUS_PREPARED     = :prepared
JOB_STATUS_FINISHED     = :finished
JOB_STATUS_FAILED       = :failed
JOB_STATUS_QUEUED       = :queued

WORKER_STATUS_STARTING  = :starting
WORKER_STATUS_WAITING   = :waiting
WORKER_STATUS_RUNNING   = :running
WORKER_STATUS_FINISHED  = :finished
WORKER_STATUS_TIMEOUT   = :timeout
WORKER_STATUS_CRASHED   = :crashed
WORKER_STATUS_CLEANING  = :cleaning


# Logging and startup
LOG_PIPE_LEN            = 10
LOG_COL_WID             = 8
LOG_COL_JID             = JOB_IDENT_LEN+3+2
LOG_COL_ID              = 6
LOG_TRIM_LINE           = 80
LOG_DUMPS               = File.dirname(__FILE__) + "/../../log/"
LOG_ROTATION            = "daily"
LOG_FORMAT_TIME         = "%Y-%m-%d %H:%M:%S"
LOG_FORMAT_PREFIX       = "%s %s\t%-#{LOG_PIPE_LEN.to_i}s\t"
LOG_FORMAT_MESSAGE      = "%#{-LOG_COL_WID.to_i}s\t%#{-LOG_COL_JID.to_i}s\t%#{-LOG_COL_ID.to_i}s"
LOG_NEWLINE             = "\n"
LOG_INDENT              = "\t"


# Notifications
NOTIFY_PREFIX           = "rftpd"
NOTIFY_USERAGENT        = "#{APP_NAME}/v#{APP_VER}"
NOTIFY_IDENTIFIER_LEN   = 4


# Dashboard row styles
DASHBOARD_JOB_STYLES = {
  JOB_STATUS_QUEUED     => :active,
  JOB_STATUS_FAILED     => :warning,
  JOB_STATUS_FINISHED   => :success,
  JOB_STATUS_UPLOADING  => :info,
  JOB_STATUS_RENAMING   => :info,
  }
DASHBOARD_WORKER_STYLES = {
  waiting:              :success,
  working:              :info,
  crashed:              :danger,
  done:                 :success,
  dead:                 :danger
  }


# Configuration defaults
DEFAULT_WORKER_TIMEOUT  = 3600
DEFAULT_FTP_CHUNK       = 512
DEFAULT_PAGE_SIZE       = 40
DEFAULT_WORKERS         = 1


# Initialize defaults
APP_STARTED = Time.now
APP_LIBS = File.dirname(__FILE__)


