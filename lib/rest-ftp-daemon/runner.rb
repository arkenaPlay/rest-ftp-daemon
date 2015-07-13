require 'optparse'
require 'daemons'


module RestFtpDaemon
  class Runner
    class << self

      def run argv
        # Extract main command
        @command = ARGV.shift

        # Parse options and check compliance
        @options = {}
        begin
          parse.order!(argv)
        rescue OptionParser::InvalidOption => e
          abort "EXITING: option parser: #{e.message}"
        else
          abort parser.to_s unless ["start", "stop"].include? command
        end

        # Declare constants
        APP_CONF = @options[:config]
        APP_ENV = @options[:env]

        # Depending on command
        case @command
        when "start"
          command_start
        when "stop"
          command_stop
        end

        puts @options.inspect
      end

      # def inject_cli_options
      # end

      def command_start
        puts "command_start: daemonizing"
        @pid_file = "/tmp/cell.pid"
        daemonize

        puts "command_start: daemonized, running"
        #RestFtpDaemon::Application.run(options)
        puts "command_start: FINISHED !?"
      end

      def command_stop
      end

      def daemonize
        remove_stale_pid_file
        Daemons.daemonize
        write_pid_file
      end

      def pid
        File.exist?(@pid_file) && !File.zero?(@pid_file) ? open(@pid_file).read.to_i : nil
      end

    protected

      def parse argv
        # Declare parser
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: #{File.basename $0} [options] start|stop"
          opts.on("-c", "--config CONFIGFILE")                                 { |config| options["config"] = config }
          opts.on("-e", "--environment ENV")                                   { |env| options["env"] = env }
          opts.on("",   "--dev")                                               { options["env"] = "development" }
          opts.on("-p", "--port PORT", "use PORT")                             { |port| options["port"] = port.to_i }
          opts.on("-w", "--workers COUNT", "Use COUNT worker threads")         { |count| options["workers"] = count.to_i }
          opts.on("-d", "--daemonize", "Run daemonized in the background")     { |bool| options["daemonize"] = true }
          opts.on("-f", "--foreground", "Run in the foreground")               { |bool| options["daemonize"] = false }
          opts.on("-P", "--pid FILE", "File to store PID")                     { |file| options["pidfile"] = file }
          opts.on("-u", "--user NAME", "User to run daemon as (use with -g)")  { |user| options["user"] = user }
          opts.on("-g", "--group NAME", "Group to run daemon as (use with -u)"){ |group| options["group"] = group }

          opts.separator ""
          opts.on_tail("-h", "--help", "Show this message")                    do
            puts opts
            puts TAIL_MESSAGE unless File.exists?(DEFAULT_CONFIG_PATH)
            exit
          end
          opts.on_tail("-v", "--version", "Show version (#{APP_VER})")         { puts APP_VER; exit }
        end

        # Detect options from ARGV
        parser.order!(argv)
      end


      # If PID file is stale, remove it.
      def remove_stale_pid_file
        return unless File.exist?(@pid_file)

        if pid && Process.running?(pid)
          abort "#{@pid_file} already exists, already running (process ID: #{pid})"

        else
          puts "Deleting stale PID file #{@pid_file}"
          remove_pid_file
        end
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

      # def wait_for_file(state, file)
      #   Timeout.timeout(@options[:timeout] || 30) do
      #     case state
      #     when :creation then sleep 0.1 until File.exist?(file)
      #     when :deletion then sleep 0.1 while File.exist?(file)
      #     end
      #   end
      # end

    end
  end
end
