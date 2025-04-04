# frozen_string_literal: true

require 'spec_helper'

describe 'ProSA::TelemetryLevel' do
  [
    'off',
    'OFF',
    'error',
    'Error',
    'warn',
    'wARN',
    'info',
    'INfo',
    'debug',
    'trace',
  ].each do |allowed_value|
    it { is_expected.to allow_value(allowed_value) }
  end

  [
    'garbage',
    '',
    [],
    ['info'],
    'thisiswarning',
    'errorerror',
  ].each do |invalid_value|
    it { is_expected.not_to allow_value(invalid_value) }
  end
end
