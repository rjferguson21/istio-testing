import { createNetworkPolicy } from "./lib.ts";

/**
 * Creates common network policies for a namespace (default deny + istio-system/DNS egress)
 */
export async function createCommonNetworkPolicies(
  namespace: string
): Promise<void> {
  // Default deny all traffic
  await createNetworkPolicy({
    metadata: {
      name: "default-deny-all",
      namespace: namespace,
    },
    spec: {
      podSelector: {},
      policyTypes: ["Ingress", "Egress"],
    },
  });

  // Allow egress to istio-system and DNS
  await createNetworkPolicy({
    metadata: {
      name: "allow-istio-system-egress",
      namespace: namespace,
    },
    spec: {
      podSelector: {},
      policyTypes: ["Egress"],
      egress: [
        // Allow all pods to reach istio-system namespace
        {
          to: [
            {
              namespaceSelector: {
                matchLabels: {
                  "kubernetes.io/metadata.name": "istio-system",
                },
              },
            },
          ],
        },
        // Allow DNS queries to kube-system
        {
          to: [
            {
              namespaceSelector: {
                matchLabels: {
                  "kubernetes.io/metadata.name": "kube-system",
                },
              },
            },
          ],
          ports: [
            {
              protocol: "UDP",
              port: 53,
            },
          ],
        },
      ],
    },
  });
}

/**
 * Creates an ingress network policy that allows HBONE traffic (port 15008) from a source namespace
 */
export async function createIngressHBONEPolicy(
  namespace: string,
  appName: string,
  sourceNamespace: string,
  policyName: string
): Promise<void> {
  await createNetworkPolicy({
    metadata: {
      name: policyName,
      namespace: namespace,
    },
    spec: {
      podSelector: {
        matchLabels: {
          app: appName,
        },
      },
      policyTypes: ["Ingress"],
      ingress: [
        {
          from: [
            {
              namespaceSelector: {
                matchLabels: {
                  "kubernetes.io/metadata.name": sourceNamespace,
                },
              },
            },
          ],
          ports: [
            {
              protocol: "TCP",
              port: 15008, // HBONE (HTTP-Based Overlay Network Encapsulation) port
            },
          ],
        },
      ],
    },
  });
}

/**
 * Creates an egress network policy that allows HBONE traffic (port 15008) to a destination namespace
 */
export async function createEgressHBONEPolicy(
  namespace: string,
  appName: string,
  destinationNamespace: string,
  policyName: string
): Promise<void> {
  await createNetworkPolicy({
    metadata: {
      name: policyName,
      namespace: namespace,
    },
    spec: {
      podSelector: {
        matchLabels: {
          app: appName,
        },
      },
      policyTypes: ["Egress"],
      egress: [
        {
          to: [
            {
              namespaceSelector: {
                matchLabels: {
                  "kubernetes.io/metadata.name": destinationNamespace,
                },
              },
            },
          ],
          ports: [
            {
              protocol: "TCP",
              port: 15008, // HBONE (HTTP-Based Overlay Network Encapsulation) port
            },
          ],
        },
      ],
    },
  });
}

/**
 * Creates a basic ingress network policy that allows traffic on a specific port from a source namespace
 */
export async function createBasicIngressPolicy(
  namespace: string,
  appName: string,
  sourceNamespace: string,
  port: number,
  policyName: string
): Promise<void> {
  await createNetworkPolicy({
    metadata: {
      name: policyName,
      namespace: namespace,
    },
    spec: {
      podSelector: {
        matchLabels: {
          app: appName,
        },
      },
      policyTypes: ["Ingress"],
      ingress: [
        {
          from: [
            {
              namespaceSelector: {
                matchLabels: {
                  "kubernetes.io/metadata.name": sourceNamespace,
                },
              },
            },
          ],
          ports: [
            {
              protocol: "TCP",
              port: port,
            },
          ],
        },
      ],
    },
  });
}

/**
 * Creates a basic egress network policy that allows traffic on a specific port to a destination namespace
 */
export async function createBasicEgressPolicy(
  namespace: string,
  appName: string,
  destinationNamespace: string,
  port: number,
  policyName: string
): Promise<void> {
  await createNetworkPolicy({
    metadata: {
      name: policyName,
      namespace: namespace,
    },
    spec: {
      podSelector: {
        matchLabels: {
          app: appName,
        },
      },
      policyTypes: ["Egress"],
      egress: [
        {
          to: [
            {
              namespaceSelector: {
                matchLabels: {
                  "kubernetes.io/metadata.name": destinationNamespace,
                },
              },
            },
          ],
          ports: [
            {
              protocol: "TCP",
              port: port,
            },
          ],
        },
      ],
    },
  });
}
