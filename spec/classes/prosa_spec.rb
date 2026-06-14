# frozen_string_literal: true

require 'spec_helper'

describe 'prosa' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.not_to contain_file('/usr/local/bin/prosa-monitor') }

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
    end
  end
end
