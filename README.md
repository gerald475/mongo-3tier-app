Three Tier Cloud Native Application on Kubernetes

This project serves as a practical implementation of a full-stack three-tier architecture designed for high availability and automated delivery. By leveraging Kubernetes, I established a resilient environment that manages containerized microservices, persistent database storage, and a robust continuous integration pipeline. This application demonstrates the core principles of modern infrastructure management through the lens of a cloud-native workflow.
Architectural Rationale

I chose this specific stack because it closely mirrors production environments found in major cloud providers. While a cloud environment would utilize managed services like Amazon RDS or Google Cloud SQL, I opted to deploy a containerized MongoDB instance within my cluster to maintain control over my data lifecycle and to practice managing persistent volumes manually. This approach provided me with a deeper understanding of how data persistence and stateful sets function under the hood of a Kubernetes cluster.
Key Domains of Focus

    Security: I prioritized securing my data layer by moving connection strings out of my codebase and into Kubernetes secrets. This prevents sensitive information from being exposed in version control. I implemented this because credential management is a foundational pillar of secure infrastructure and remains a primary concern in any DevOps lifecycle.

    Networking: My networking strategy utilized an ingress controller to manage external access to the application. This is a standard practice that mimics how I would use a load balancer in a production cloud environment. I configured this to ensure that traffic is routed efficiently while keeping internal services hidden from the public internet.

    Storage: Persistence was achieved through persistent volume claims. In a cloud environment, I would likely lean on dynamic provisioning from a cloud provider. Here, I implemented a custom configuration that allowed me to simulate that behavior, ensuring my database state persists even if my application pods are rescheduled or restarted.

Challenges and Resolution

Throughout the deployment process, I encountered hurdles that required significant investigation. The most frequent challenge involved troubleshooting pod failures or unauthorized access errors during authentication handshakes.

    Authentication Handshakes: I relied heavily on checking logs to diagnose these issues. By using the command line to inspect logs from specific pods, I could pinpoint exactly where the handshake between my identity provider and the API server was breaking down.

    Persistent Volume Conflicts: I faced an error when trying to redeploy the MongoDB manifest, as the storage was still bound to a previous pod. I resolved this by identifying the orphaned Persistent Volume Claim (PVC) and cleaning up the stale resources to allow for a fresh binding to the new deployment.

Deployment Guide

To deploy this project on your local machine using Minikube, follow these steps in order. This sequence ensures that the infrastructure (namespaces and RBAC) is ready before the application components attempt to bind to them.

    Start Minikube with OIDC:
    minikube start --extra-config=apiserver.oidc-issuer-url=[https://three-tier.local/dex](https://three-tier.local/dex) --extra-config=apiserver.oidc-client-id=kubernetes-cluster --extra-config=apiserver.oidc-ca-file=/var/lib/minikube/certs/ca.crt
    Reasoning: The API server must be configured to trust the OIDC provider before any authentication can occur.

    Apply Namespaces:
    kubectl apply -f namespace.yaml
    Reasoning: Establishes the auth and three-tier isolation boundaries.

    Deploy Auth and RBAC:
    kubectl apply -f dex-rbac.yaml, kubectl apply -f enterprise-rbac.yaml, kubectl apply -f dex-stack.yaml
    Reasoning: Identity management is a dependency for the application layer.

    Deploy Data Layer:
    kubectl apply -f mongo-pv.yaml, kubectl apply -f mongo-pvc.yaml, kubectl apply -f mongo-secrets.yaml, kubectl apply -f mongo-deployment.yaml
    Reasoning: Ensures the database is available to accept connections from the backend.

    Deploy Application and Networking:
    kubectl apply -f backend-deployment.yaml, kubectl apply -f frontend-deployment.yaml, kubectl apply -f network-policies.yaml, kubectl apply -f three-tier-ingress.yaml
    Reasoning: The application and traffic management components rely on the previous layers being fully operational.
