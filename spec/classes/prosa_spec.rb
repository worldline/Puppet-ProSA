# frozen_string_literal: true

require 'spec_helper'

describe 'prosa' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.not_to contain_file('/usr/local/bin/prosa-monitor') }

      it { is_expected.to contain_file('/etc/prosa/prosa.yml').that_notifies('Class[prosa::service]') }
      it { is_expected.to contain_file('/etc/systemd/system/prosa.service').with_content(%r{^# config_auto_reload=false$}).that_notifies('Service[prosa]') }

      it do
        is_expected.to contain_file('/etc/systemd/system/prosa.service')
          .with_content(%r{^Wants=network-online\.target$})
          .with_content(%r{^After=network-online\.target$})
          .with_content(%r{^Restart=on-failure$})
          .with_content(%r{^RestartSec=5$})
      end

      context 'with config_auto_reload enabled' do
        let(:params) { { config_auto_reload: true } }

        it { is_expected.to contain_file('/etc/systemd/system/prosa.service').with_content(%r{^# config_auto_reload=true$}).that_notifies('Service[prosa]') }
      end

      context 'with the shared observability endpoint' do
        let(:params) do
          {
            observability: {
              'endpoint' => '0.0.0.0:19092',
              'metrics' => {
                'stdout' => {
                  'level' => 'info',
                },
              },
            },
          }
        end

        it do
          is_expected.to contain_file('/etc/prosa/prosa.yml')
            .with_content(%r{^  endpoint: 0\.0\.0\.0:19092$})
            .with_content(%r{^  metrics:$})
        end

        it do
          is_expected.to contain_file('/usr/local/bin/prosa-monitor')
            .with_content(%r{DEFAULT_METRICS_URL = "http://127\.0\.0\.1:19092/metrics"})
        end
      end

      context 'with both the shared and the legacy Prometheus endpoints' do
        let(:params) do
          {
            observability: {
              'endpoint' => '0.0.0.0:19093',
              'metrics' => {
                'prometheus' => {
                  'endpoint' => '0.0.0.0:19094',
                },
              },
            },
          }
        end

        it do
          is_expected.to contain_file('/usr/local/bin/prosa-monitor')
            .with_content(%r{DEFAULT_METRICS_URL = "http://127\.0\.0\.1:19093/metrics"})
        end
      end

      context 'with an endpoint without address' do
        let(:params) { { observability: { 'endpoint' => '19095' } } }

        it { is_expected.to compile.and_raise_error(%r{Invalid ProSA Prometheus endpoint '19095'}) }
      end

      context 'with Prometheus metrics enabled' do
        let(:params) do
          {
            observability: {
              'metrics' => {
                'prometheus' => {
                  'endpoint' => '0.0.0.0:19090',
                },
              },
              'traces' => {
                'stdout' => {
                  'level' => 'info',
                },
              },
              'logs' => {
                'stdout' => {
                  'level' => 'info',
                },
              },
            },
          }
        end

        it do
          is_expected.to contain_file('/usr/local/bin/prosa-monitor')
            .with(
              ensure: 'file',
              owner: 'root',
              group: 'root',
              mode: '0755',
            )
            .with_content(%r{DEFAULT_METRICS_URL = "http://127\.0\.0\.1:19090/metrics"})
        end
      end

      context 'with Prometheus metrics enabled and a custom monitor path' do
        let(:params) do
          {
            monitor_path: '/usr/local/bin/prosa-monitor-instance-a',
            observability: {
              'metrics' => {
                'prometheus' => {
                  'endpoint' => '0.0.0.0:19091',
                },
              },
              'traces' => {
                'stdout' => {
                  'level' => 'info',
                },
              },
              'logs' => {
                'stdout' => {
                  'level' => 'info',
                },
              },
            },
          }
        end

        it do
          is_expected.to contain_file('/usr/local/bin/prosa-monitor-instance-a')
            .with(
              ensure: 'file',
              owner: 'root',
              group: 'root',
              mode: '0755',
            )
            .with_content(%r{DEFAULT_METRICS_URL = "http://127\.0\.0\.1:19091/metrics"})
        end
      end
    end
  end
end
