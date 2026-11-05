# frozen_string_literal: true

require 'spec_helper'

describe 'ProSA::Observability' do
  [
    {},
    { 'endpoint' => '0.0.0.0:9090' },
    { 'metrics' => { 'prometheus' => { 'endpoint' => '0.0.0.0:9090' } } },
    {
      'endpoint' => '0.0.0.0:9090',
      'metrics' => { 'stdout' => { 'level' => 'info' } },
      'traces' => { 'otlp' => { 'endpoint' => 'grpc://localhost:4317' } },
      'logs' => { 'stdout' => { 'level' => 'info' } },
    },
  ].each do |allowed_value|
    it { is_expected.to allow_value(allowed_value) }
  end

  [
    { 'endpoint' => '' },
    { 'endpoint' => { 'address' => '0.0.0.0:9090' } },
    { 'metrics' => 'stdout' },
    { 'unknown' => { 'stdout' => { 'level' => 'info' } } },
    'garbage',
  ].each do |invalid_value|
    it { is_expected.not_to allow_value(invalid_value) }
  end
end
