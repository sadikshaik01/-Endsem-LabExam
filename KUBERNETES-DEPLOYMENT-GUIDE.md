# Kubernetes Deployment Guide for Car Rental Application

## Prerequisites

Before deploying to Kubernetes, ensure you have:

1. **Docker Desktop** installed and running with Kubernetes enabled
   - OR **Minikube** installed and running

2. **kubectl** installed and configured
   - Check: `kubectl version --client`

3. **Docker Hub images** pushed (✓ Already done!)
   - Frontend: `sadikshaik01/endsem-frontend:v2`
   - Backend: `sadikshaik01/endsem-backend:v1`

## Quick Start - Deploy in 1 Command

Navigate to the `Sample-Ansible-Playbook-template` directory and run:

```powershell
.\deploy-to-kubernetes.ps1
```

This script will:
- ✓ Check if kubectl is installed
- ✓ Verify Kubernetes cluster connection
- ✓ Apply all Kubernetes manifests
- ✓ Wait for all pods to be ready
- ✓ Display deployment status and access URLs

---

## Manual Deployment Steps

If you prefer to deploy manually, follow these steps:

### Step 1: Start Your Kubernetes Cluster

**Option A - Using Docker Desktop:**
```powershell
# Enable Kubernetes in Docker Desktop Settings
# Settings > Kubernetes > Enable Kubernetes
```

**Option B - Using Minikube:**
```powershell
minikube start --driver=docker --memory=4000 --cpus=2
```

### Step 2: Verify Cluster Connection

```powershell
kubectl cluster-info
kubectl get nodes
```

### Step 3: Deploy the Application

```powershell
cd "c:\Users\shaik\OneDrive\Desktop\end lab\Sample-Ansible-Playbook-template"
kubectl apply -f k8s\fullstackdeployment.yaml
```

You should see:
```
persistentvolumeclaim/mysql-pvc created
deployment.apps/mysql created
deployment.apps/backend created
configmap/frontend-config created
deployment.apps/frontend created
service/mysql created
service/backend created
service/frontend created
```

### Step 4: Monitor Deployment

**Check all pods:**
```powershell
kubectl get pods -w
```

Wait until all pods show `Running` status:
```
NAME                        READY   STATUS    RESTARTS   AGE
mysql-xxx                   1/1     Running   0          2m
backend-xxx                 1/1     Running   0          2m
backend-yyy                 1/1     Running   0          2m
frontend-xxx                1/1     Running   0          2m
frontend-yyy                1/1     Running   0          2m
```

**Check services:**
```powershell
kubectl get services
```

You should see:
```
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
mysql        ClusterIP   10.x.x.x        <none>        3306/TCP         2m
backend      NodePort    10.x.x.x        <none>        8081:30083/TCP   2m
frontend     NodePort    10.x.x.x        <none>        8080:30082/TCP   2m
```

### Step 5: Access Your Application

**For Docker Desktop Kubernetes:**
- Frontend: http://localhost:30082
- Backend: http://localhost:30083

**For Minikube:**

Get Minikube IP:
```powershell
minikube ip
```

Then access:
- Frontend: http://<MINIKUBE-IP>:30082
- Backend: http://<MINIKUBE-IP>:30083

**Alternative - Using Port Forwarding:**
```powershell
# In one terminal
kubectl port-forward svc/frontend 8080:8080

# In another terminal
kubectl port-forward svc/backend 8081:8081
```

Then access:
- Frontend: http://localhost:8080
- Backend: http://localhost:8081

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────┐
│           Kubernetes Cluster                     │
│                                                  │
│  ┌────────────┐      ┌─────────────┐           │
│  │  Frontend  │      │   Backend   │           │
│  │   (x2)     │─────▶│    (x2)     │           │
│  │ Port: 8080 │      │  Port: 8081 │           │
│  └────────────┘      └─────────────┘           │
│       │                      │                  │
│       │                      ▼                  │
│       │              ┌─────────────┐           │
│       │              │    MySQL    │           │
│       │              │  Port: 3306 │           │
│       │              │   (PVC 5Gi) │           │
│       │              └─────────────┘           │
│       │                                         │
└───────┼─────────────────────────────────────────┘
        │
        ▼
   NodePort 30082 (Frontend)
   NodePort 30083 (Backend)
```

## Resources Created

1. **PersistentVolumeClaim**: `mysql-pvc` (5Gi storage for MySQL)
2. **Deployments**:
   - `mysql` (1 replica)
   - `backend` (2 replicas)
   - `frontend` (2 replicas)
3. **Services**:
   - `mysql` (ClusterIP - internal only)
   - `backend` (NodePort 30083)
   - `frontend` (NodePort 30082)
4. **ConfigMap**: `frontend-config` (Backend URL configuration)

## Configuration Details

### Database Configuration
- **Database Name**: carrental
- **Username**: root
- **Password**: root
- **Port**: 3306

### Backend Configuration
- **Image**: sadikshaik01/endsem-backend:v1
- **Port**: 8081
- **Replicas**: 2
- **Database URL**: jdbc:mysql://mysql:3306/carrental

### Frontend Configuration
- **Image**: sadikshaik01/endsem-frontend:v2
- **Port**: 8080
- **Replicas**: 2
- **Backend URL**: http://backend:8081

---

## Useful Commands

### View Resources
```powershell
# View all resources
kubectl get all

# View pods with more details
kubectl get pods -o wide

# View services
kubectl get svc

# View deployments
kubectl get deployments

# View persistent volumes
kubectl get pvc
```

### Check Logs
```powershell
# Backend logs
kubectl logs -l app=backend --tail=100 -f

# Frontend logs
kubectl logs -l app=frontend --tail=100 -f

# MySQL logs
kubectl logs -l app=mysql --tail=100 -f

# Logs from specific pod
kubectl logs <pod-name>
```

### Debug Issues
```powershell
# Describe pod (shows events and errors)
kubectl describe pod <pod-name>

# Check pod events
kubectl get events --sort-by=.metadata.creationTimestamp

# Execute commands inside a pod
kubectl exec -it <pod-name> -- /bin/bash

# Check environment variables in backend pod
kubectl exec -it <backend-pod-name> -- env | grep SPRING
```

### Scale Deployments
```powershell
# Scale backend to 3 replicas
kubectl scale deployment backend --replicas=3

# Scale frontend to 4 replicas
kubectl scale deployment frontend --replicas=4
```

### Update Deployments
```powershell
# After updating your deployment file
kubectl apply -f k8s\fullstackdeployment.yaml

# Restart a deployment (useful after updating images)
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/frontend

# Check rollout status
kubectl rollout status deployment/backend
```

### Delete Resources
```powershell
# Delete all resources from the deployment file
kubectl delete -f k8s\fullstackdeployment.yaml

# Delete specific resources
kubectl delete deployment backend
kubectl delete service frontend
kubectl delete pvc mysql-pvc
```

---

## Troubleshooting

### Problem: Pods are not starting

**Solution:**
```powershell
# Check pod status
kubectl get pods

# Describe the problematic pod
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name>
```

### Problem: Cannot access application via NodePort

**For Docker Desktop:**
- Ensure Kubernetes is enabled in Docker Desktop settings
- Use `localhost` as the IP

**For Minikube:**
```powershell
# Get Minikube IP
minikube ip

# Or use minikube service command
minikube service frontend
minikube service backend
```

### Problem: Backend cannot connect to MySQL

**Solution:**
```powershell
# Check if MySQL pod is running
kubectl get pods -l app=mysql

# Check MySQL logs
kubectl logs -l app=mysql

# Test connection from backend pod
kubectl exec -it <backend-pod-name> -- nc -zv mysql 3306
```

### Problem: Frontend cannot connect to Backend

**Check backend service:**
```powershell
kubectl get svc backend

# Check if backend pods are running
kubectl get pods -l app=backend

# Check backend logs for errors
kubectl logs -l app=backend
```

### Problem: Image pull errors

**Solution:**
```powershell
# Check if image names are correct in deployment file
kubectl describe pod <pod-name> | grep -i image

# If images are private, create a Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=<your-username> \
  --docker-password=<your-password>

# Update deployment to use the secret
# Add to pod spec:
# imagePullSecrets:
# - name: regcred
```

---

## Testing Your Deployment

### Test Frontend Access
```powershell
# Test if frontend is accessible
curl http://localhost:30082

# Or in browser
Start-Process "http://localhost:30082"
```

### Test Backend API
```powershell
# Test backend health/status endpoint
curl http://localhost:30083

# Test specific API endpoint (adjust as per your API)
curl http://localhost:30083/api/users
```

### Test Database Connection
```powershell
# Connect to MySQL pod
kubectl exec -it <mysql-pod-name> -- mysql -uroot -proot carrental

# Inside MySQL, run:
# SHOW DATABASES;
# USE carrental;
# SHOW TABLES;
```

---

## Next Steps

1. **Set up Ingress** for better URL routing (optional)
2. **Configure Horizontal Pod Autoscaling** (HPA)
3. **Add Health Checks** (liveness/readiness probes)
4. **Set up Monitoring** with Prometheus and Grafana
5. **Configure Secrets** for sensitive data instead of plain text passwords
6. **Set up CI/CD Pipeline** for automatic deployments

---

## Cleanup

To completely remove the deployment:

```powershell
# Delete all resources
kubectl delete -f k8s\fullstackdeployment.yaml

# Verify deletion
kubectl get all

# If using Minikube, you can stop it
minikube stop

# Or delete the entire Minikube cluster
minikube delete
```

---

## Summary

✓ Fixed database name from 'ecommerce' to 'carrental'
✓ Fixed backend port from 8080 to 8081
✓ Docker images already pushed to Docker Hub
✓ Kubernetes deployment file ready
✓ Deployment script created
✓ All configuration aligned with your application

**You're ready to deploy! Run the deployment script:**
```powershell
cd "c:\Users\shaik\OneDrive\Desktop\end lab\Sample-Ansible-Playbook-template"
.\deploy-to-kubernetes.ps1
```
