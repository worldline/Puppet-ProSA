#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'json'
require 'open3'
require 'socket'
require 'time'

DEFAULT_MONITOR_PATH = '/usr/local/bin/prosa-monitor'

# Exit codes of `prosa-monitor --check`
EXIT_READY = 0
EXIT_NOT_READY = 1

input = $stdin.read
params = input.strip.empty? ? {} : JSON.parse(input)
monitor_path = params['monitor_path'] || DEFAULT_MONITOR_PATH

result = {
  hostname: Socket.gethostname,
  timestamp: Time.now.utc.iso8601,
  monitor_path: monitor_path,
}
exit_code = 2

begin
  if File.executable?(monitor_path)
    stdout, stderr, status = Open3.capture3(monitor_path, '--check')
    exit_code = status.exitstatus || 2
    case exit_code
    when EXIT_READY
      result[:status] = 'ready'
    when EXIT_NOT_READY
      result[:status] = 'not_ready'
    else
      result[:status] = 'error'
      result[:error] = stderr.strip.empty? ? stdout.strip : stderr.strip
    end
  else
    result[:status] = 'error'
    result[:error] = "Monitoring script not found or not executable: #{monitor_path}"
  end
rescue StandardError => e
  result[:status] = 'error'
  result[:error] = e.message
end

puts JSON.pretty_generate(result)
exit exit_code
