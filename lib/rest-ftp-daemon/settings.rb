# Configuration class
class Settings < Settingslogic
  # Read configuration
  namespace (defined?(APP_ENV) ? APP_ENV : "production")
  source ((const_defined?(:APP_CONF) && File.exists?(APP_CONF)) ? APP_CONF : Hash.new)
  suppress_errors true

  # Compute my PID filename
  def pidfile
    port = self["port"]
    self["pidfile"] || "/tmp/#{APP_NAME}.port#{port}.pid"
  end

  # Direct access to any depth
  def at *path
    val = path.reduce(Settings) { |m, key| m && m[key.to_s] }
    val.nil? ? (yield if block_given?) : val
  end

  # Dump whole settings set to readable YAML
  def dump
    to_hash.to_yaml(indent: 4, useheader: true, useversion: false )
  end

  def init_defaults
    Settings["host"] ||= `hostname`.chomp.split(".").first
  end

  def newrelic_enabled?
    Settings.at(:debug, :newrelic)
  end

  def init_newrelic
    # Skip if not enabled
    return ENV["NEWRELIC_AGENT_ENABLED"] = "false" unless Settings.newrelic_enabled?

    # Enable module
    ENV["NEWRELIC_AGENT_ENABLED"] = "true"
    ENV["NEW_RELIC_MONITOR_MODE"] = "true"

    # License
    ENV["NEW_RELIC_LICENSE_KEY"] = Settings.at(:debug, :newrelic)

    # Appname
    ENV["NEW_RELIC_APP_NAME"] = "#{APP_NICK}-#{Settings.host}-#{APP_ENV}"

    # Logfile
    ENV["NEW_RELIC_LOG"] = Settings.at(:logs, :newrelic)
  end

end
