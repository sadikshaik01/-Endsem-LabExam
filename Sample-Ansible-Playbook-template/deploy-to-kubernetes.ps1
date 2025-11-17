# ========================================
# Kubernetes Deployment Script
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Kubernetes Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if kubectl is installed
Write-Host "[1/7] Checking if kubectl is installed..." -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Host "✓ kubectl is installed: $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ kubectl is not installed. Please install kubectl first." -ForegroundColor Red
    Write-Host "  Install from: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 2: Check if Minikube is running (optional)
Write-Host "[2/7] Checking Kubernetes cluster connection..." -ForegroundColor Yellow
try {
    $clusterInfo = kubectl cluster-info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Connected to Kubernetes cluster" -ForegroundColor Green
    } else {
        Write-Host "⚠ Warning: Cannot connect to Kubernetes cluster" -ForegroundColor Yellow
        Write-Host "  If using Minikube, run: minikube start" -ForegroundColor Yellow
        Write-Host "  If using Docker Desktop, enable Kubernetes in settings" -ForegroundColor Yellow
        $continue = Read-Host "Do you want to continue anyway? (y/n)"
        if ($continue -ne 'y') {
            exit 1
        }
    }
} catch {
    Write-Host "⚠ Warning: Cannot connect to Kubernetes cluster" -ForegroundColor Yellow
    Write-Host "  Make sure your Kubernetes cluster is running" -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Apply Kubernetes manifests
Write-Host "[3/7] Applying Kubernetes manifests..." -ForegroundColor Yellow
$manifestPath = Join-Path $PSScriptRoot "k8s\fullstackdeployment.yaml"

if (Test-Path $manifestPath) {
    kubectl apply -f $manifestPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Kubernetes manifests applied successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to apply Kubernetes manifests" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✗ Manifest file not found: $manifestPath" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 4: Wait for MySQL to be ready
Write-Host "[4/7] Waiting for MySQL pod to be ready..." -ForegroundColor Yellow
Write-Host "  This may take a few minutes..." -ForegroundColor Gray
$maxWaitTime = 300  # 5 minutes
$elapsed = 0
$interval = 5

while ($elapsed -lt $maxWaitTime) {
    $mysqlReady = kubectl get pods -l app=mysql -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>$null
    if ($mysqlReady -eq "True") {
        Write-Host "✓ MySQL pod is ready" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds $interval
    $elapsed += $interval
    Write-Host "  Waiting... ($elapsed seconds elapsed)" -ForegroundColor Gray
}

if ($elapsed -ge $maxWaitTime) {
    Write-Host "⚠ Warning: MySQL pod took too long to be ready" -ForegroundColor Yellow
}

Write-Host ""

# Step 5: Wait for Backend to be ready
Write-Host "[5/7] Waiting for Backend pods to be ready..." -ForegroundColor Yellow
$elapsed = 0
while ($elapsed -lt $maxWaitTime) {
    $backendReady = kubectl get pods -l app=backend -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>$null
    $readyCount = ($backendReady -split " " | Where-Object { $_ -eq "True" }).Count
    if ($readyCount -ge 1) {
        Write-Host "✓ Backend pods are ready ($readyCount/2)" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds $interval
    $elapsed += $interval
    Write-Host "  Waiting... ($elapsed seconds elapsed)" -ForegroundColor Gray
}

Write-Host ""

# Step 6: Wait for Frontend to be ready
Write-Host "[6/7] Waiting for Frontend pods to be ready..." -ForegroundColor Yellow
$elapsed = 0
while ($elapsed -lt $maxWaitTime) {
    $frontendReady = kubectl get pods -l app=frontend -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' 2>$null
    $readyCount = ($frontendReady -split " " | Where-Object { $_ -eq "True" }).Count
    if ($readyCount -ge 1) {
        Write-Host "✓ Frontend pods are ready ($readyCount/2)" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds $interval
    $elapsed += $interval
    Write-Host "  Waiting... ($elapsed seconds elapsed)" -ForegroundColor Gray
}

Write-Host ""

# Step 7: Display deployment information
Write-Host "[7/7] Deployment Summary" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "Pods Status:" -ForegroundColor White
kubectl get pods

Write-Host ""
Write-Host "Services:" -ForegroundColor White
kubectl get services

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get Minikube IP or use localhost
$minikubeIP = "localhost"
try {
    $minikubeIPCheck = minikube ip 2>$null
    if ($LASTEXITCODE -eq 0 -and $minikubeIPCheck) {
        $minikubeIP = $minikubeIPCheck
    }
} catch {
    # Use localhost if minikube is not available
}

Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Frontend: http://${minikubeIP}:30082" -ForegroundColor Green
Write-Host "  Backend:  http://${minikubeIP}:30083" -ForegroundColor Green
Write-Host ""

if ($minikubeIP -eq "localhost") {
    Write-Host "Note: If using Minikube, you may need to run 'minikube service frontend' or 'minikube service backend'" -ForegroundColor Yellow
    Write-Host "      Or use port forwarding: kubectl port-forward svc/frontend 30082:8080" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Yellow
Write-Host "  View pods:              kubectl get pods" -ForegroundColor White
Write-Host "  View services:          kubectl get svc" -ForegroundColor White
Write-Host "  View logs (backend):    kubectl logs -l app=backend" -ForegroundColor White
Write-Host "  View logs (frontend):   kubectl logs -l app=frontend" -ForegroundColor White
Write-Host "  Delete deployment:      kubectl delete -f k8s\fullstackdeployment.yaml" -ForegroundColor White
Write-Host ""
