import { K8s, kind } from "kubernetes-fluent-client";

/**
 * Creates a namespace with optional Istio mode
 * @param namespace - The name of the namespace to create
 * @param mode - The Istio mode: "sidecar", "ambient", or "none"
 */
export async function createNamespaceWithMode(
  namespace: string,
  mode: "sidecar" | "ambient" | "none"
): Promise<void> {
  const labels: Record<string, string> = {};

  switch (mode) {
    case "sidecar":
      console.log(`Enabling sidecar injection for namespace ${namespace}...`);
      labels["istio-injection"] = "enabled";
      break;
    case "ambient":
      console.log(`Adding namespace ${namespace} to ambient mesh...`);
      labels["istio.io/dataplane-mode"] = "ambient";
      break;
    case "none":
      console.log(`Creating namespace ${namespace} without Istio injection...`);
      break;
    default:
      console.log(`Warning: Unknown mode '${mode}'. Creating namespace without Istio injection.`);
  }

  await K8s(kind.Namespace).Apply({
    metadata: {
      name: namespace,
      labels: labels,
    },
  });

  console.log(`✓ Namespace ${namespace} created successfully`);
}

/**
 * Creates a Kubernetes Service
 */
export async function createService(service: any): Promise<void> {
  console.log(`Creating service ${service.metadata.name}...`);
  await K8s(kind.Service).Apply(service);
  console.log(`✓ Service ${service.metadata.name} created successfully`);
}

/**
 * Creates a Kubernetes Deployment
 */
export async function createDeployment(deployment: any): Promise<void> {
  console.log(`Creating deployment ${deployment.metadata.name}...`);
  await K8s(kind.Deployment).Apply(deployment);
  console.log(`✓ Deployment ${deployment.metadata.name} created successfully`);
}

/**
 * Creates a Kubernetes NetworkPolicy
 */
export async function createNetworkPolicy(networkPolicy: any): Promise<void> {
  console.log(`Creating network policy ${networkPolicy.metadata.name}...`);
  await K8s(kind.NetworkPolicy).Apply(networkPolicy);
  console.log(`✓ Network policy ${networkPolicy.metadata.name} created successfully`);
}
