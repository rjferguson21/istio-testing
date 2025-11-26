import { deployReceiverApp, deployClientApp } from "./lib/deploy.ts";

// Deploy the ambient receiver app
await deployReceiverApp({
  name: "ambient-app-receive",
  istioMode: "ambient",
  ingressSources: [
    { namespace: "ambient-app", istioMode: "ambient" },
    { namespace: "sidecar-app", istioMode: "sidecar" },
    { namespace: "non-mesh-app", istioMode: "none" },
  ],
});

// Deploy the sidecar receiver app
await deployReceiverApp({
  name: "sidecar-app-receive",
  istioMode: "sidecar",
  ingressSources: [
    { namespace: "ambient-app", istioMode: "ambient" },
    { namespace: "sidecar-app", istioMode: "sidecar" },
  ],
});

// Deploy the ambient client app
await deployClientApp({
  name: "ambient-app",
  istioMode: "ambient",
  targets: [
    { service: "sidecar-app-receive", namespace: "sidecar-app-receive", istioMode: "sidecar" },
    { service: "ambient-app-receive", namespace: "ambient-app-receive", istioMode: "ambient" },
  ],
});

// Deploy the sidecar client app
await deployClientApp({
  name: "sidecar-app",
  istioMode: "sidecar",
  targets: [
    { service: "ambient-app-receive", namespace: "ambient-app-receive", istioMode: "ambient" },
    { service: "sidecar-app-receive", namespace: "sidecar-app-receive", istioMode: "sidecar" },
  ],
});

// Deploy the non-mesh client app
await deployClientApp({
  name: "non-mesh-app",
  istioMode: "none",
  targets: [
    { service: "ambient-app-receive", namespace: "ambient-app-receive", istioMode: "ambient" },
  ],
});