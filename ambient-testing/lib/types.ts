export interface IngressSource {
  namespace: string;
  istioMode: "sidecar" | "ambient" | "none";
}

export interface ReceiverAppConfig {
  name: string;
  istioMode: "sidecar" | "ambient" | "none";
  ingressSources: IngressSource[];
}

export interface ClientTarget {
  service: string;
  namespace: string;
  istioMode: "sidecar" | "ambient" | "none";
}

export interface ClientAppConfig {
  name: string;
  istioMode: "sidecar" | "ambient" | "none";
  targets: ClientTarget[];
}
