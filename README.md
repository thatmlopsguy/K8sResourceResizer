# K8sResourceResizer

A tool that optimizes Kubernetes resource limits and requests based on historical usage patterns.

## Overview

`K8sResourceResizer` optimizes Kubernetes resource configurations through historical usage pattern analysis. It implements Prophet, Ensemble, and Time-aware approaches to set optimal CPU and memory settings. The tool integrates with Amazon Managed Prometheus (AMP) for metrics collection and supports ArgoCD workflows. Core features include business hours awareness, trend detection, and time window analysis. Users can run it locally or integrate it into CI/CD pipelines with GitHub Actions.

## Features

- Prophet, Ensemble, and Time-aware prediction strategies
- Historical analysis with configurable time windows
- Business hours awareness
- Trend detection and analysis
- Amazon Managed Prometheus (AMP) integration
- ArgoCD integration for GitOps workflows

## Prerequisites

- Python 3.8 or higher
- Access to Kubernetes cluster
- ArgoCD for GitOps integration

## License

This library uses the MIT-0 License. See the LICENSE file.
