import { createService, createDeployment } from "./lib.ts";

/**
 * Creates a receiver app (service and deployment)
 */
export async function createReceiverApp(
  namespace: string,
  appName: string,
  serviceName: string
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
              image: "hashicorp/http-echo:latest",
              args: [`-text=Hello from ${appName}!`, "-listen=:8080"],
              ports: [
                {
                  containerPort: 8080,
                  name: "http",
                },
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
