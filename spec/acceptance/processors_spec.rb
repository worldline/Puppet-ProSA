# frozen_string_literal: true

require 'spec_helper_acceptance'

prosa_hash = prosa_settings_hash

describe 'prosa::processors class' do
  context 'custom processors defined via class prosa::processors' do
    let(:facts) do
      {
        'networking' => {
          'hostname' => 'acceptance'
        }
      }
    end

    pp = <<-MANIFEST
        class { 'prosa':
          prosa_name      => #{prosa_hash['prosa_name']},
          service_manage  => false,
          telemetry_level => 'warn',
          telemetry_attributes => {
            'service.name' => 'prosa-service',
            'host.id'      => 'fdbf79e8af94cb7f9e8df36789187052',
          },
          observability   => {
            'metrics' => {
              'prometheus' => {
                'endpoint' => '0.0.0.0:9090',
              },
            },
            'traces'  => {
              'stdout' => {
                'level' => 'info',
              },
            },
            'logs'    => {
              'stdout' => {
                'level' => 'info',
              },
            },
          },
        }
        class { 'prosa::processors':
          processors => {
            'stub-1' => {
                'adaptor_config_path' => undef,
                'proc_restart_duration_period' => undef,
                'proc_max_restart_period' => undef,
                'proc_settings' => {
                  'service_names' => ['test'],
                },
            },
            'inj-1' => {
              'proc_settings' => {
                'service_name' => 'test',
              },
            },
            'custom-1' => {
              'adaptor_config_path' => '#{prosa_hash['conf_dir']}/custom-adaptor.yml',
              'adaptor_settings' => {
                'adapt' => true,
              },
              'proc_settings' => {
                'out' => 'local',
              },
            },
          },
        }
    MANIFEST
    it 'creates custom processor config files' do
      apply_manifest(pp, catch_failures: true)
    end

    describe file("#{prosa_hash['conf_dir']}/prosa.yml") do
      it { is_expected.to contain 'name: prosa-acceptance' }
      it { is_expected.to contain '    service.name: prosa-service' }
      it { is_expected.to contain '    host.id: fdbf79e8af94cb7f9e8df36789187052' }
      it { is_expected.to contain '    prometheus:' }
    end

    describe file("#{prosa_hash['conf_dir']}/stub-1.yml") do
      it { is_expected.to contain '  service_names:' }
    end

    describe file("#{prosa_hash['conf_dir']}/inj-1.yml") do
      it { is_expected.to contain '  service_name: test' }
    end

    describe file("#{prosa_hash['conf_dir']}/custom-1.yml") do
      it { is_expected.to contain "  adaptor_config_path: \"#{prosa_hash['conf_dir']}/custom-adaptor.yml\"" }
    end

    describe file("#{prosa_hash['conf_dir']}/custom-adaptor.yml") do
      it { is_expected.to contain 'adapt: true' }
    end
  end
end
