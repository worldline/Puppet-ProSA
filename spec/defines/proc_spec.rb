# frozen_string_literal: true

require 'spec_helper'

describe 'prosa::proc' do
  let :pre_condition do
    "class {'prosa':}"
  end

  let(:title) { 'namevar' }

  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_file('/etc/prosa/namevar.yml').that_notifies('Class[prosa::service]') }
      it {
        is_expected.to contain_exec('prosa new processor namevar')
          .with_creates('/etc/prosa/namevar.yml')
          .that_comes_before('File[/etc/prosa/namevar.yml]')
          .that_notifies('Class[prosa::service]')
      }

      context 'with config_auto_reload enabled' do
        let :pre_condition do
          "class {'prosa': config_auto_reload => true }"
        end

        it { is_expected.to contain_file('/etc/prosa/namevar.yml').without_notify.that_comes_before('Class[prosa::service]') }
        it { is_expected.to contain_exec('prosa new processor namevar').that_notifies('Class[prosa::service]') }
      end
    end
  end
end
