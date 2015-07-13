require 'optparse'
require 'daemons'


module RestFtpDaemon
  class Runner
    class << self

      def run argv
        # Init
        options = {}

        # Parse options and check compliance
        begin
          cli_options = options_parser argv

        rescue OptionParser::InvalidOption => e
          say "config: option parser: #{e.message}"
          abort

        end

        # Load settings
        load_settings_and_override_with cli_options
        @pid_file = Settings.pidfile

        # Choose action depending on command
        command = argv.shift
        case command
        when "start"


          remove_stale_pid_file
          command_start

        when "stop"
          command_stop

        else
          say cli_options[:usage]
        end

      end

      def command_start
        # PID file
        remove_stale_pid_file

        # Load libs
        say "loading libs"
        require File.join APP_ROOT, "lib", APP_NAME

        # Switch to daemon mode
        say "starting daemon"

        # Daemonize and write PID file
        if Settings.daemonize
          Daemons.daemonize
          write_pid_file
        end

        # Run application
        RestFtpDaemon::Application.dummy
        # RestFtpDaemon::Application.run(options)
      end

      def command_stop
        send_kill_signal if Settings.daemonize
      end

      def pid
        File.exist?(@pid_file) && !File.zero?(@pid_file) ? open(@pid_file).read.to_i : nil
      end

    protected

      def say text
        puts "#{APP_NAME}: #{text}"
      end

      def load_settings_and_override_with cli_options
        # Import settings
        require_relative "settings"

        # Set defaults
        Settings.init_defaults

        # Overwrite with commandline options
        Settings.merge! cli_options if cli_options.is_a? Enumerable

        # Init NewRelic
        Settings.init_newrelic

      rescue Psych::SyntaxError => e
        abort "EXITING: config file syntax error: #{e.message}"
      rescue StandardError => e
        abort "EXITING: unknow error loading settings  #{e.inspect}"
      end

      def options_parser argv
        options = {}

        # Declare parser
        parser = OptionParser.new do |opts|
          opts.banner = "usage: #{File.basename $0} [options] start|stop"
          opts.on("-c", "--config CONFIGFILE")                                 { |config| options["config"] = config      }
          opts.on("-e", "--environment ENV")                                   { |env|    options["env"] = env            }
          opts.on("",   "--dev")                                               {          options["env"] = "development"  }
          opts.on("-p", "--port PORT", "use PORT")                             { |port|   options["port"] = port.to_i     }
          opts.on("-w", "--workers COUNT", "Use COUNT worker threads")         { |count|  options["workers"] = count.to_i }
          opts.on("-d", "--daemonize", "Run daemonized in the background")     { |bool|   options["daemonize"] = true     }
          opts.on("-f", "--foreground", "Run in the foreground")               { |bool|   options["daemonize"] = false    }
          opts.on("-P", "--pid FILE", "File to store PID")                     { |file|   options["pidfile"] = file       }
          opts.on("-u", "--user NAME", "User to run daemon as (use with -g)")  { |user|   options["user"] = user          }
          opts.on("-g", "--group NAME", "Group to run daemon as (use with -u)"){ |group|  options["group"] = group        }

          opts.separator ""
          opts.on_tail("-h", "--help", "Show this message")                    do
            puts opts
            puts TAIL_MESSAGE unless File.exists?(DEFAULT_CONFIG_PATH)
            exit
          end
          opts.on_tail("-v", "--version", "Show version (#{APP_VER})")         { puts APP_VER; exit }
        end

        # Apply parser on argv
        parser.order!(argv)

        # Append self-doc
        options[:usage] = parser.to_s

        # Return options
        options
      end

      # Send a +signal+ to the process which PID is stored in +pid_file+.
      def send_kill_signal timeout=10
        # Get the PID of expected process
        pid = read_pid_file

        # Complain if PID empty
        if pid.nil?
          say "can't stop process, no PID found in #{@pid_file}"
          return
        end

        # Softly interrupt the process
        say "sending INT signal to process #{pid}"
        Process.kill("INT", pid)

        # Wait until the process disappears
        Timeout.timeout(timeout) do
          # say "."
          sleep 0.1 while (Process.getpgid pid rescue nil)
        end

      rescue Timeout::Error, Interrupt
        say "sending KILL signal to process #{pid}"
        Process.kill("KILL", pid)
        remove_pid_file

      rescue Errno::ESRCH # No such process
        say "process #{pid} not found"
        remove_pid_file
        # remove_stale_pid_file

      else
        say "process #{pid} terminated"
        remove_pid_file

      end

      def read_pid_file
        return nil unless @pid_file
        return nil unless File.file? @pid_file
        return nil unless pid = File.read(@pid_file)

        pid.to_i
      end

      def remove_stale_pid_file
        return unless File.exist?(@pid_file)

        # Get the PID of expected process
        pid = read_pid_file
        return if !pid

        # Try to find a running process
        running = Process.getpgid pid

        rescue Errno::ESRCH   # No such process
          say "stale #{@pid_file} found, process ##{pid} not running"
          remove_pid_file
          #abort

        else
          abort "process ##{pid}) already running"

      end

      def remove_pid_file
        File.delete(@pid_file) if @pid_file && File.exists?(@pid_file)
      end

      def write_pid_file
        pid = Process.pid
        puts "Writing PID #{pid} to #{@pid_file}"
        open(@pid_file,"w") { |f| f.write(pid) }
        File.chmod(0644, @pid_file)
      end

    end
  end
end
