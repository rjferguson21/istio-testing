import { createNamespaceWithMode } from "./lib.ts";
import { createReceiverApp } from "./receiver.ts";
import { createClientApp } from "./client.ts";
import {
  createCommonNetworkPolicies,
  createIngressHBONEPolicy,
  createBasicIngressPolicy,
  createBasicEgressPolicy,
  createEgressHBONEPolicy,
} from "./netpol.ts";
import type { ReceiverAppConfig, ClientAppConfig } from "./types.ts";

export async function deployReceiverApp(config: ReceiverAppConfig) {
  const { name, istioMode, ingressSources } = config;

  // Create namespace
  await createNamespaceWithMode(name, istioMode);

  // Create App
  await createReceiverApp(name, name, name);

  // Create Common NetworkPolicies (default deny + istio-system/DNS egress)
  await createCommonNetworkPolicies(name);

  // Create ingress NetworkPolicies based on source and target modes
  for (const source of ingressSources) {
    // Determine the correct ingress policy based on source and target modes
    if (source.istioMode === "none" || istioMode === "none") {
      // Non-mesh source OR non-mesh target: use basic port 8080
      await createBasicIngressPolicy(
        name,
        name,
        source.namespace,
        8080,
        `allow-from-${source.namespace}`
      );
    } else if (source.istioMode === "sidecar" && istioMode === "sidecar") {
      // Sidecar-to-sidecar: use direct port 8080
      await createBasicIngressPolicy(
        name,
        name,
        source.namespace,
        8080,
        `allow-from-${source.namespace}`
      );
    } else {
      // Any other mesh combination (ambient involved): use HBONE
      await createIngressHBONEPolicy(
        name,
        name,
        source.namespace,
        `allow-from-${source.namespace}`
      );
    }
  }

  console.log("");
  console.log(`Namespace: ${name}`);
  console.log(`Service: ${name}.${name}.svc.cluster.local:8080`);
}

export async function deployClientApp(config: ClientAppConfig) {
  const { name, istioMode, targets } = config;

  // Create namespace
  await createNamespaceWithMode(name, istioMode);

  // Create App
  await createClientApp(name, name, name, targets);

  // Create Common NetworkPolicies (default deny + istio-system/DNS egress)
  await createCommonNetworkPolicies(name);

  // Create NetworkPolicies - egress to each target
  for (const target of targets) {
    // Determine the correct egress policy based on source and target modes
    if (istioMode === "none" || target.istioMode === "none") {
      // Non-mesh source OR non-mesh target: use basic port 8080
      await createBasicEgressPolicy(
        name,
        name,
        target.namespace,
        8080,
        `allow-to-${target.namespace}`
      );
    } else if (istioMode === "sidecar" && target.istioMode === "sidecar") {
      // Sidecar-to-sidecar: use direct port 8080
      await createBasicEgressPolicy(
        name,
        name,
        target.namespace,
        8080,
        `allow-to-${target.namespace}`
      );
    } else {
      // Any other mesh combination (ambient involved): use HBONE
      await createEgressHBONEPolicy(
        name,
        name,
        target.namespace,
        `allow-to-${target.namespace}`
      );
    }
  }

  console.log("");
  console.log(`Namespace: ${name}`);
  console.log(`Service: ${name}.${name}.svc.cluster.local:8080`);
  console.log("Targets:");
  targets.forEach((target) => {
    console.log(`  - ${target.service}.${target.namespace}.svc.cluster.local:8080`);
  });
}
