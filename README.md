# Puppet ProSA

## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
    * [What the ProSA module affects](#what-prosa-module-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with prosa](#beginning-with-prosa)
1. [Usage](#usage)
1. [Limitations](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

[ProSA](https://github.com/worldline/ProSA) (**Pro**tocol **S**ervice **A**daptor) is a framework designed to provide a simple and lightweight protocol service adaptor for service-oriented architectures.
This [Puppet module](https://www.puppet.com/docs/puppet/8/modules_fundamentals.html) managed with [PDK](https://puppet.com/docs/pdk/latest/pdk_generating_modules.html) streamlines the process of creating configurations to manage ProSA in your infrastructure.
It is capable of configuring and managing a range of processors.
For more information on deploying ProSA, please refer to [cargo-prosa](https://github.com/worldline/ProSA/tree/main/cargo-prosa).

## Setup

### What the ProSA module affects

- Service and configuration files for ProSA
- ProSA processor configuration files

### Setup Requirements

This module does not install dependencies required for your specific ProSA instance, such as OpenSSL.
You will need to install these dependencies separately according to your ProSA setup.

### Beginning with prosa

To have Puppet install ProSA with the default parameters, declare the [`prosa`][https://forge.puppet.com/modules/worldline/prosa/reference#prosa] class:

```puppet
class { 'prosa': }
```

When you declare this class with the default options, the module:

- Installs the ProSA instace binary from the configured [_bin_repo_](https://forge.puppet.com/modules/worldline/prosa/reference#-prosa--bin_repo).
- Generate configuration files in the [`conf_dir`](https://forge.puppet.com/modules/worldline/prosa/reference#-prosa--conf_dir).
- Creates and starts a ProSA service.

## Usage

### ProSA base

To set up ProSA, you need to use the [`prosa`][https://forge.puppet.com/modules/worldline/prosa/reference#prosa] class.

From this class, you should specify the binary repository to retrieve the ProSA binary.
Additionally, observability is configured by default, but you may need to specify parameters based on your particular stack.
For more details on configuration, please refer to the [ProSA configuration guide](https://worldline.github.io/ProSA/ch01-02-config.html).

```puppet
class { 'prosa':
  bin_repo        => 'https://user:password@binary.repo.com/repository/prosa-1.0.0.bin',
  telemetry_level => 'info',
  observability   => {
    'metrics' => {
      'otlp' => {
        'endpoint' => 'http://opentelemetry-collector:4317',
        'protocol' => 'Grpc'
      },
    },
    'traces' => {
      'otlp' => {
        'endpoint' => 'http://opentelemetry-collector:4317',
        'protocol' => 'Grpc'
      },
      'stdout' => {
        'level' => 'info',
      },
    },
    'logs' => {
      'otlp' => {
        'endpoint' => 'http://opentelemetry-collector:4317',
        'protocol' => 'Grpc'
      },
      'stdout' => {
        'level' => 'info',
      },
    },
  }
}
```

With this configuration, ProSA will be installed and ready to accept processors.
Configuring processors is the next step.

### Configuring Processors

Processors are configured using the [`prosa::proc`](https://forge.puppet.com/modules/worldline/prosa/reference#prosa--proc) defined type.
You can set them up individually or use [`prosa::processors`](https://forge.puppet.com/modules/worldline/prosa/reference#prosa--processors) for all:
```puppet
class { 'prosa::processors':
  processors => {
    'stub' => {
      'proc_settings' => {
        'service_names' => ['test'],
      },
    },
    'inj' => {
      'proc_settings' => {
        'service_name' => 'test',
      },
    },
  }
}
```

Since processors have different configurations, `proc_settings` is provided as a `Hash` to accommodate all necessary configuration options.
To determine which configurations to specify, refer to the documentation for the corresponding processor.

## Reference

For information on classes, types and functions see the [REFERENCE.md](./REFERENCE.md)

## Limitations

Limitations are associated with the ProSA binary generated with cargo-prosa.
You need to pay attention to the compiled architecture of your binary.
Additionally, if you are using external binaries (e.g., OpenSSL), you'll need to install them independently.

## Development

For development guidelines, please follow [contributing](./CONTRIBUTING.md) rules.

If you submit a change to this module, be sure to regenerate the reference documentation as follows:

```bash
puppet strings generate --format markdown --out REFERENCE.md
```

Acceptance tests are runs with [litmus](https://puppetlabs.github.io/litmus/Running-acceptance-tests.html)

## Authors

### Worldline

- [Jérémy HERGAULT](https://github.com/reneca)
