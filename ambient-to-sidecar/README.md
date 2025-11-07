# Istio Ambient to Sidecar Testing

This project tests network connectivity and minimum required network policies between Istio ambient mesh and sidecar-enabled namespaces.

## Overview

The test setup verifies the minimum network policy requirements (assuming a default deny network policy) to allow traffic from an ambient-enrolled namespace to a sidecar-enabled namespace.

## Quick Start

To deploy the entire test environment:

```bash
./cross.sh
```

This will automatically run `cluster.sh` to create the base cluster, then deploy both test applications.

## Manual Setup

### 1. Create Base Cluster

```bash
./cluster.sh
```

Creates a Kubernetes cluster with Istio installed.

### 2. Deploy Ambient App

```bash
./ambient-app.sh
```

- Creates a namespace `ambient-app` enrolled in ambient mesh
- Deploys an application that polls the sidecar app
- Target: sidecar app in `sidecar-app` namespace

### 3. Deploy Sidecar App

```bash
./sidecar-app.sh
```

- Creates a namespace `sidecar-app` with sidecar injection enabled
- Deploys an application to receive traffic from the ambient app

## Architecture

```text
┌─────────────────────┐          ┌─────────────────────┐
│  ambient-app (ns)   │          │  sidecar-app (ns)   │
│  ┌───────────────┐  │  HTTP    │  ┌───────────────┐  │
│  │  Ambient App  │──┼─────────>│  │  Sidecar App  │  │
│  │  (polling)    │  │          │  │  (target)     │  │
│  └───────────────┘  │          │  └───────────────┘  │
│  Ambient Mesh       │          │  Sidecar Injection  │
└─────────────────────┘          └─────────────────────┘
```

## Testing Objectives

- Verify cross-namespace communication between ambient and sidecar modes
- Identify minimum NetworkPolicy requirements for ambient-to-sidecar traffic
- Validate Istio configuration for mixed deployment models
