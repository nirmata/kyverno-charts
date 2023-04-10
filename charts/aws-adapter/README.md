# kyverno-aws-adapter

## Description

Kyverno AWS Adapter is a Kubernetes controller for the `AWSAdapterConfig` CRD. As of now, it observes the realtime state of an EKS cluster and reconciles it with the currently stored state, but can be further expanded to other AWS services later on by extending the current API with the help of [AWS SDK for Go v2](https://github.com/aws/aws-sdk-go-v2).

## Getting Started

Check out the [getting_started.md](https://github.com/nirmata/kyverno-aws-adapter/blob/main/docs/getting_started.md) guide for installing the Nirmata Kyverno Adapter for AWS.

For more information please refer to the [kyverno-aws-adapter](https://github.com/nirmata/kyverno-aws-adapter) repository.
