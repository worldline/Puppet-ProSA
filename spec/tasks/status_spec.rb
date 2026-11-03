# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

describe 'prosa::status task' do
  let(:task) { File.expand_path('../../tasks/status.rb', __dir__) }
  let(:dir) { Dir.mktmpdir('prosa-status-spec') }

  after(:each) { FileUtils.remove_entry(dir) }

  # Stub of `prosa-monitor --check` that prints `out` and exits with `code`.
  def monitor_stub(out, code)
    path = File.join(dir, 'prosa-monitor')
    File.write(path, "#!/bin/sh\necho '#{out}'\nexit #{code}\n")
    File.chmod(0o755, path)
    path
  end

  def run_task(params)
    out, _err, status = Open3.capture3(RbConfig.ruby, task, stdin_data: params.to_json)
    [JSON.parse(out), status.exitstatus]
  end

  it 'reports a ready instance' do
    result, code = run_task(monitor_path: monitor_stub('ready', 0))
    expect([result['status'], code]).to eq(['ready', 0])
  end

  it 'reports a not ready instance' do
    result, code = run_task(monitor_path: monitor_stub('not ready', 1))
    expect([result['status'], code]).to eq(['not_ready', 1])
  end

  it 'reports the monitor error' do
    result, code = run_task(monitor_path: monitor_stub('no prosa_ready metric', 2))
    expect([result['status'], result['error'], code]).to eq(['error', 'no prosa_ready metric', 2])
  end

  it 'reports a monitor crash as an error' do
    result, code = run_task(monitor_path: monitor_stub('Traceback', 1))
    expect([result['status'], code]).to eq(['error', 2])
  end

  it 'fails when the monitoring script is missing' do
    result, code = run_task(monitor_path: File.join(dir, 'missing'))
    expect([result['status'], code]).to eq(['error', 2])
    expect(result['error']).to include('not found')
  end
end
