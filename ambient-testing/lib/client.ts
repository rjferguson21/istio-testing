import { createService, createDeployment } from "./lib.ts";
import type { ClientTarget } from "./types.ts";

/**
 * Creates a client app that polls multiple target services
 */
export async function createClientApp(
  namespace: string,
  appName: string,
  serviceName: string,
  targets: ClientTarget[]
): Promise<void> {
  console.log(`Deploying ${appName}...`);

  // Create service
  await createService({
    metadata: {
      name: serviceName,
      namespace: namespace,
      labels: {
        app: appName,
      },
    },
    spec: {
      ports: [
        {
          port: 8080,
          name: "http",
        },
      ],
      selector: {
        app: appName,
      },
    },
  });

  // Build the polling script
  const pollingScript = targets
    .map(
      (target) => `
            echo "$(date): Polling ${target.service}..."
            if curl -s -o /dev/null -w "%{http_code}" http://${target.service}.${target.namespace}.svc.cluster.local:8080 | grep -q "200"; then
              echo "✓ Successfully connected to ${target.service}"
            else
              echo "✗ Failed to connect to ${target.service}"
            fi
`
    )
    .join("\n");

  // Create deployment
  await createDeployment({
    metadata: {
      name: appName,
      namespace: namespace,
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: {
          app: appName,
        },
      },
      template: {
        metadata: {
          labels: {
            app: appName,
          },
        },
        spec: {
          containers: [
            {
              name: appName,
              image: "curlimages/curl:latest",
              command: ["/bin/sh"],
              args: [
                "-c",
                `
          while true; do
${pollingScript}
            sleep 5
          done
        `,
              ],
              resources: {
                requests: {
                  memory: "32Mi",
                  cpu: "100m",
                },
                limits: {
                  memory: "64Mi",
                  cpu: "200m",
                },
              },
            },
          ],
        },
      },
    },
  });

  console.log(`✓ ${appName} deployed successfully!`);
}
