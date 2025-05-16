import express from "express";
import bodyParser from "body-parser";
import * as k8s from "@kubernetes/client-node";
import fs from "fs";
import https from "https";

const app = express();

// Parse JSON bodies
app.use(bodyParser.json());

// Initialize Kubernetes client
const saTokenPath = "/var/run/secrets/kubernetes.io/serviceaccount/token";

let kc = new k8s.KubeConfig();
let k8sApi;
try {
  if (fs.existsSync(saTokenPath)) {
    // authenticate with service account token (production)
    kc.loadFromCluster();
  } else {
    // authenticate with kubeconfig (development)
    kc.loadFromDefault();
    kc.setCurrentContext("kind-kind");

    const currentCluster = kc.getCurrentCluster();
    if (currentCluster) {
      if (
        currentCluster.server.includes("127.0.0.1") ||
        currentCluster.server.includes("localhost")
      ) {
        currentCluster.server = "https://kind-control-plane:6443";
      }
    }
  }
  k8sApi = kc.makeApiClient(k8s.CoreV1Api);
} catch (error) {
  console.error("Error loading kubeconfig:", error);
  process.exit(1);
}

// Root endpoint
app.get("/", (req, res) => {
  res.json({ message: "handle root" });
});

// Endpoint to list all pods
app.get("/pods", async (req, res) => {
  try {
    // const podsRes = await k8sApi.listNamespacedPod({ namespace: "default" });
    const podsRes = await k8sApi.listPodForAllNamespaces();
    res.json(podsRes.items);
  } catch (error) {
    console.error("Error fetching pods:", error);
    res.status(500).json({
      error: "Failed to fetch pods",
      message: error.message,
    });
  }
});

// Mutating webhook endpoint
app.post("/mutate", (req, res) => {
  const admissionReview = req.body;
  const pod = admissionReview?.request?.object;
  if (!pod) {
    console.error("No pod object found in request");
    return res.status(400).json({ error: "Invalid admission request" });
  }

  const labelKey = "webhook-modified";
  const labelValue = "true";

  const currentLabels = pod.metadata?.labels || {};
  const newLabels = {
    ...currentLabels,
    [labelKey]: labelValue,
  };
  const patchStr = JSON.stringify([
    {
      op: "add",
      path: "/metadata/labels",
      value: newLabels,
    },
  ]);
  const patchBase64 = Buffer.from(patchStr).toString("base64");
  const admissionResponse = {
    apiVersion: "admission.k8s.io/v1",
    kind: "AdmissionReview",
    response: {
      uid: admissionReview.request.uid,
      allowed: true,
      patchType: "JSONPatch",
      patch: patchBase64,
      status: {
        message: `Added label ${labelKey}=${labelValue}`,
      },
    },
  };

  res.json(admissionResponse);
});

const port = process.env.PORT || 8443;
const tlsCertPath = "/etc/webhook/certs/tls.crt";
const tlsKeyPath = "/etc/webhook/certs/tls.key";
const enableTLS = process.env.ENABLE_TLS === "true";

if (enableTLS) {
  try {
    console.log(
      `Loading TLS certificate from ${tlsCertPath} and key from ${tlsKeyPath}`
    );
    const options = {
      cert: fs.readFileSync(tlsCertPath),
      key: fs.readFileSync(tlsKeyPath),
    };

    https.createServer(options, app).listen(port, () => {
      console.log(
        `Secure webhook server running on port ${port} with TLS enabled`
      );
    });
  } catch (error) {
    console.error(`Failed to start secure server: ${error.message}`);
    console.log("Falling back to non-TLS mode...");

    app.listen(port, () => {
      console.log(
        `Webhook server running on port ${port} without TLS (fallback mode)`
      );
    });
  }
} else {
  app.listen(port, () => {
    console.log(`Webhook server running on port ${port} without TLS`);
  });
}
