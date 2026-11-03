#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'open3'
require 'puppet'

PROSA_BIN = '/usr/local/bin/prosa'.freeze

def parse_prosa_version(output)
  result = {
    prosa_version: nil,
    core: nil,
    modules: {}
  }

  current_module = nil

  output.each_line do |line|
    case line
    # Première ligne: prosa 0.1.12 - core::main::MainProc = { crate = prosa, version = 0.3.4 }
    when %r{^prosa\s+([\d.]+)\s+-\s+(\S+)\s+=\s+\{\s*crate\s*=\s*(\S+),\s*version\s*=\s*([\d.]+)\s*\}}
      result[:prosa_version] = Regexp.last_match(1)
      result[:core] = {
        name: Regexp.last_match(2),
        crate: Regexp.last_match(3),
        version: Regexp.last_match(4)
      }

    # Nom du module (ligne avec juste le nom, indenté avec 2 espaces)
    when %r{^  (\w+)\s*$}
      current_module = Regexp.last_match(1)
      result[:modules][current_module] = {}

    # Processor: jptr::JptrProc = { crate = prosa-proc-jptr, version = 0.2.1 }
    when %r{^\s+Processor:\s*(\S+)\s*=\s*\{\s*crate\s*=\s*(\S+),\s*version\s*=\s*([\d.]+)\s*\}}
      if current_module
        result[:modules][current_module][:processor] = {
          name: Regexp.last_match(1),
          crate: Regexp.last_match(2),
          version: Regexp.last_match(3)
        }
      end

    # Adaptor: jptr::JptrTranspAdaptor = { crate = prosa-proc-jptr, version = 0.2.1 }
    when %r{^\s+Adaptor\s*:\s*(\S+)\s*=\s*\{\s*crate\s*=\s*(\S+),\s*version\s*=\s*([\d.]+)\s*\}}
      if current_module
        result[:modules][current_module][:adaptor] = {
          name: Regexp.last_match(1),
          crate: Regexp.last_match(2),
          version: Regexp.last_match(3)
        }
      end
    end
  end

  result
end

# Exécution principale
result = {
  hostname: `hostname`.strip,
  timestamp: Time.now.utc.iso8601
}

begin
  unless File.executable?(PROSA_BIN)
    result[:status] = 'error'
    result[:error] = "Binary not found or not executable: #{PROSA_BIN}"
    puts result.to_json
    exit 1
  end

  stdout, stderr, status = Open3.capture3(PROSA_BIN, '--version')

  if status.success?
    result[:status] = 'success'
    result.merge!(parse_prosa_version(stdout))
  else
    result[:status] = 'error'
    result[:error] = stderr.strip
  end
rescue => e
  result[:status] = 'error'
  result[:error] = e.message
end

puts JSON.pretty_generate(result)
