# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'socket'
require 'tmpdir'

PYTHON = `command -v python3 2>/dev/null`.strip
PYTHON_VERSION = PYTHON.empty? ? [0, 0] : `#{PYTHON} -c 'import sys; print(*sys.version_info[:2])'`.split.map(&:to_i)

METRICS_READY = <<~METRICS
  prosa_ready{service_name="prosa",host_name="h1"} 1
  prosa_main_ram{type="physical",service_name="prosa",host_name="h1"} 1048576
  prosa_processors{type="node",id="1",title="stub",service_name="prosa",host_name="h1"} 0
METRICS

describe 'prosa' do
  let(:facts) { on_supported_os.values.first }
  let(:params) do
    {
      observability: {
        'metrics' => { 'prometheus' => { 'endpoint' => '127.0.0.1:19090' } },
        'traces' => { 'stdout' => { 'level' => 'info' } },
        'logs' => { 'stdout' => { 'level' => 'info' } },
      },
    }
  end

  let(:script) { catalogue.resource('File', '/usr/local/bin/prosa-monitor')[:content] }

  let(:dir) { Dir.mktmpdir('prosa-monitor-spec') }

  before(:each) { File.write(File.join(dir, 'prosa-monitor'), script) }

  after(:each) { FileUtils.remove_entry(dir) }

  def run_monitor(*args)
    Open3.capture3(PYTHON, '-I', File.join(dir, 'prosa-monitor'), *args)
  end

  # Serves `body` at /metrics on a free local port while the block runs.
  def with_metrics(body)
    root = File.join(dir, 'www')
    Dir.mkdir(root)
    File.write(File.join(root, 'metrics'), body)
    port = TCPServer.open('127.0.0.1', 0) { |s| s.addr[1] }
    pid = Process.spawn(PYTHON, '-I', '-m', 'http.server', port.to_s, '--bind', '127.0.0.1', '--directory', root,
                        out: File::NULL, err: File::NULL)
    begin
      50.times do
        TCPSocket.new('127.0.0.1', port).close
        break
      rescue Errno::ECONNREFUSED
        sleep 0.1
      end
      yield "http://127.0.0.1:#{port}/metrics"
    ensure
      Process.kill('TERM', pid)
      Process.wait(pid)
    end
  end

  context 'prosa-monitor script', if: (PYTHON_VERSION <=> [3, 8]) >= 0 do
    # The script must keep running on the oldest supported python3 (3.6 on RHEL 8).
    it 'only uses Python 3.6 syntax' do
      _out, err, status = Open3.capture3(
        PYTHON, '-I', '-c',
        'import ast, sys; ast.parse(open(sys.argv[1]).read(), feature_version=(3, 6))',
        File.join(dir, 'prosa-monitor')
      )
      expect(status.success?).to be(true), err
    end

    it 'reports a ready instance' do
      with_metrics(METRICS_READY) do |url|
        out, _err, status = run_monitor('--check', url)
        expect([out.strip, status.exitstatus]).to eq(['ready', 0])

        out, _err, status = run_monitor('--no-color', url)
        expect(out).to include('Ready: yes')
        expect(status.exitstatus).to eq(0)
      end
    end

    it 'reports a not ready instance' do
      with_metrics(METRICS_READY.sub('} 1', '} 0')) do |url|
        out, _err, status = run_monitor('--check', url)
        expect([out.strip, status.exitstatus]).to eq(['not ready', 1])
      end
    end

    it 'fails when the prosa_ready metric is absent' do
      with_metrics(METRICS_READY.lines.reject { |l| l.start_with?('prosa_ready') }.join) do |url|
        _out, err, status = run_monitor('--check', url)
        expect(status.exitstatus).to eq(2)
        expect(err).to include('no prosa_ready metric')
      end
    end

    it 'fails when the endpoint is unreachable' do
      port = TCPServer.open('127.0.0.1', 0) { |s| s.addr[1] }
      _out, _err, status = run_monitor('--check', "http://127.0.0.1:#{port}/metrics")
      expect(status.exitstatus).to eq(2)
    end

    it 'fails when the connection is reset' do
      server = TCPServer.new('127.0.0.1', 0)
      thread = Thread.new do
        client = server.accept
        client.setsockopt(Socket::SOL_SOCKET, Socket::SO_LINGER, [1, 0].pack('ii'))
        client.readpartial(1024)
        client.close
      end
      _out, err, status = run_monitor('--check', "http://127.0.0.1:#{server.addr[1]}/metrics")
      thread.join
      server.close
      expect(status.exitstatus).to eq(2)
      expect(err).not_to include('Traceback')
    end

    it 'rejects a non positive watch interval' do
      _out, err, status = run_monitor('--watch', '0')
      expect(status.exitstatus).to eq(2)
      expect(err).not_to include('Traceback')
    end
  end
end
