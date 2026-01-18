# OpenShift Quick Deployment Guide

## Social Media Microservices Platform

This guide provides step-by-step instructions for deploying the Social Media Platform on OpenShift.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Quick Deployment (5 Minutes)](#2-quick-deployment-5-minutes)
3. [Detailed Deployment Steps](#3-detailed-deployment-steps)
4. [Configuration](#4-configuration)
5. [Verification](#5-verification)
6. [Troubleshooting](#6-troubleshooting)
7. [Cleanup](#7-cleanup)

---

## 1. Prerequisites

### Required Tools

```bash
# Install OpenShift CLI
# Download from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/

# Verify installation
oc version
```

### Required Access

- OpenShift cluster access (e.g., [Red Hat Developer Sandbox](https://developers.redhat.com/developer-sandbox))
- GitHub account with repository access
- Terminal/Command Line

---

## 2. Quick Deployment (5 Minutes)

### One-Command Deployment Script

Create and run this deployment script:

```bash
#!/bin/bash
# deploy.sh - Quick deployment script for Social Media Platform

# Configuration
PROJECT_NAME="social-media-app"
GITHUB_REPO="https://github.com/AminelMhl/Social-Media-Platform.git"
GITHUB_BRANCH="master"

# Create project
oc new-project $PROJECT_NAME 2>/dev/null || oc project $PROJECT_NAME

# Deploy PostgreSQL
echo "📦 Deploying PostgreSQL..."
oc new-app postgresql-persistent \
  --param POSTGRESQL_USER=social_user \
  --param POSTGRESQL_PASSWORD=social_pass \
  --param POSTGRESQL_DATABASE=social_db \
  --param VOLUME_CAPACITY=1Gi \
  --name=postgresql

# Wait for PostgreSQL
echo "⏳ Waiting for PostgreSQL to be ready..."
oc wait --for=condition=ready pod -l name=postgresql --timeout=120s

# Apply all OpenShift manifests
echo "📋 Applying manifests..."
oc apply -f openshift/

# Start builds
echo "🔨 Starting builds..."
for service in user-service post-service comment-service message-service frontend; do
  oc start-build $service --follow &
done
wait

# Configure environment variables
echo "🔧 Configuring services..."

# User Service
oc set env deployment/user-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  JWT_SECRET=super-secret-jwt-key-change-in-production \
  JWT_EXPIRES_IN=1d

# Post Service
oc set env deployment/post-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  USER_SERVICE_URL=http://user-service:3001

# Comment Service
oc set env deployment/comment-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  USER_SERVICE_URL=http://user-service:3001 \
  POST_SERVICE_URL=http://post-service:3002

# Message Service
oc set env deployment/message-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  JWT_SECRET=super-secret-jwt-key-change-in-production \
  USER_SERVICE_URL=http://user-service:3001

# Frontend
oc set env deployment/frontend \
  NEXT_PUBLIC_USER_SERVICE_URL=http://user-service:3001 \
  NEXT_PUBLIC_POST_SERVICE_URL=http://post-service:3002 \
  NEXT_PUBLIC_COMMENT_SERVICE_URL=http://comment-service:3003 \
  NEXT_PUBLIC_MESSAGE_SERVICE_URL=http://message-service:3004

# Get route URL
echo ""
echo "✅ Deployment complete!"
echo "🌐 Application URL:"
oc get route frontend -o jsonpath='{.spec.host}'
echo ""
```

---

## 3. Detailed Deployment Steps

### Step 1: Login to OpenShift

```bash
# Get login command from OpenShift web console
# Click on your username → Copy login command

oc login --token=sha256~XXXXX --server=https://api.cluster.example.com:6443
```

### Step 2: Create Project

```bash
# Create a new project (namespace)
oc new-project social-media-app

# Verify
oc project
```

### Step 3: Deploy PostgreSQL Database

```bash
# Deploy PostgreSQL with persistent storage
oc new-app postgresql-persistent \
  --param POSTGRESQL_USER=social_user \
  --param POSTGRESQL_PASSWORD=social_pass \
  --param POSTGRESQL_DATABASE=social_db \
  --param VOLUME_CAPACITY=1Gi

# Check deployment status
oc get pods -w

# Wait until postgresql-X-XXXXX shows STATUS: Running
```

### Step 4: Create Build Configurations

```bash
# Apply BuildConfigs and ImageStreams
oc apply -f openshift/buildconfigs.yaml

# Verify ImageStreams were created
oc get imagestreams

# Expected output:
# NAME              IMAGE REPOSITORY
# user-service      image-registry.openshift-image-registry.svc:5000/social-media-app/user-service
# post-service      image-registry.openshift-image-registry.svc:5000/social-media-app/post-service
# comment-service   image-registry.openshift-image-registry.svc:5000/social-media-app/comment-service
# message-service   image-registry.openshift-image-registry.svc:5000/social-media-app/message-service
# frontend          image-registry.openshift-image-registry.svc:5000/social-media-app/frontend
```

### Step 5: Start Builds

```bash
# Start all builds
oc start-build user-service
oc start-build post-service
oc start-build comment-service
oc start-build message-service
oc start-build frontend

# Monitor build progress
oc get builds -w

# View build logs (optional)
oc logs -f build/user-service-1
```

### Step 6: Deploy Applications

```bash
# Apply Deployments
oc apply -f openshift/deployments.yaml

# Apply Services
oc apply -f openshift/services.yaml

# Apply Routes
oc apply -f openshift/routes.yaml
```

### Step 7: Configure Environment Variables

```bash
# User Service - Auth & Database
oc set env deployment/user-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  JWT_SECRET=your-production-jwt-secret \
  JWT_EXPIRES_IN=1d

# Post Service - Database & User Service URL
oc set env deployment/post-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  USER_SERVICE_URL=http://user-service:3001

# Comment Service - Database & Dependent Services
oc set env deployment/comment-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  USER_SERVICE_URL=http://user-service:3001 \
  POST_SERVICE_URL=http://post-service:3002

# Message Service - Database, Auth & User Service
oc set env deployment/message-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  JWT_SECRET=your-production-jwt-secret \
  USER_SERVICE_URL=http://user-service:3001

# Frontend - API URLs (internal service discovery)
oc set env deployment/frontend \
  NEXT_PUBLIC_USER_SERVICE_URL=http://user-service:3001 \
  NEXT_PUBLIC_POST_SERVICE_URL=http://post-service:3002 \
  NEXT_PUBLIC_COMMENT_SERVICE_URL=http://comment-service:3003 \
  NEXT_PUBLIC_MESSAGE_SERVICE_URL=http://message-service:3004
```

---

## 4. Configuration

### Using Secrets (Recommended for Production)

```bash
# Create database secret
oc create secret generic db-credentials \
  --from-literal=DB_HOST=postgresql \
  --from-literal=DB_PORT=5432 \
  --from-literal=DB_USER=social_user \
  --from-literal=DB_PASSWORD=social_pass \
  --from-literal=DB_NAME=social_db

# Create JWT secret
oc create secret generic jwt-config \
  --from-literal=JWT_SECRET=your-super-secure-production-secret \
  --from-literal=JWT_EXPIRES_IN=1d

# Mount secrets to deployment
oc set env deployment/user-service --from=secret/db-credentials
oc set env deployment/user-service --from=secret/jwt-config
```

### Using ConfigMaps (For Non-Sensitive Config)

```bash
# Create ConfigMap for service URLs
oc create configmap service-urls \
  --from-literal=USER_SERVICE_URL=http://user-service:3001 \
  --from-literal=POST_SERVICE_URL=http://post-service:3002 \
  --from-literal=COMMENT_SERVICE_URL=http://comment-service:3003 \
  --from-literal=MESSAGE_SERVICE_URL=http://message-service:3004

# Apply to frontend
oc set env deployment/frontend --from=configmap/service-urls --prefix=NEXT_PUBLIC_
```

### Resource Limits (Optional)

```bash
# Set resource limits for a deployment
oc set resources deployment/user-service \
  --limits=cpu=500m,memory=512Mi \
  --requests=cpu=100m,memory=256Mi
```

---

## 5. Verification

### Check Pod Status

```bash
# List all pods
oc get pods

# Expected output (all should be Running):
# NAME                               READY   STATUS    RESTARTS   AGE
# comment-service-xxx-xxx            1/1     Running   0          5m
# frontend-xxx-xxx                   1/1     Running   0          5m
# message-service-xxx-xxx            1/1     Running   0          5m
# post-service-xxx-xxx               1/1     Running   0          5m
# postgresql-1-xxx                   1/1     Running   0          10m
# user-service-xxx-xxx               1/1     Running   0          5m
```

### Check Services

```bash
oc get services

# Expected output:
# NAME              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
# comment-service   ClusterIP   172.30.xxx.xxx   <none>        3003/TCP
# frontend          ClusterIP   172.30.xxx.xxx   <none>        80/TCP
# message-service   ClusterIP   172.30.xxx.xxx   <none>        3004/TCP
# post-service      ClusterIP   172.30.xxx.xxx   <none>        3002/TCP
# postgresql        ClusterIP   172.30.xxx.xxx   <none>        5432/TCP
# user-service      ClusterIP   172.30.xxx.xxx   <none>        3001/TCP
```

### Get Application URL

```bash
# Get the route URL
oc get routes

# Or get just the URL
oc get route frontend -o jsonpath='{.spec.host}'

# Example output: frontend-social-media-app.apps.cluster.example.com
```

### Test API Endpoints

```bash
# Get the frontend route
FRONTEND_URL=$(oc get route frontend -o jsonpath='{.spec.host}')

# Test the application (if you've exposed backend routes)
curl -s https://$FRONTEND_URL | head -20
```

### View Logs

```bash
# View logs for a specific service
oc logs deployment/user-service

# Follow logs in real-time
oc logs -f deployment/user-service

# View logs from a specific pod
oc logs user-service-xxx-xxx
```

---

## 6. Troubleshooting

### Common Issues

#### Issue: Build Fails

```bash
# Check build logs
oc logs build/user-service-1

# Common fixes:
# 1. Verify GitHub repository is accessible
# 2. Check Dockerfile path is correct
# 3. Ensure all dependencies are in package.json
```

#### Issue: Pod CrashLoopBackOff

```bash
# Check pod logs
oc logs <pod-name>

# Check events
oc get events --sort-by=.lastTimestamp

# Common causes:
# 1. Database connection failed
# 2. Missing environment variables
# 3. Port already in use
```

#### Issue: Database Connection Failed

```bash
# Verify PostgreSQL is running
oc get pods | grep postgresql

# Check PostgreSQL logs
oc logs deployment/postgresql

# Test connection from another pod
oc rsh <any-running-pod>
psql -h postgresql -U social_user -d social_db
```

#### Issue: Service Not Found (503 errors)

```bash
# Check service exists
oc get service user-service

# Check service endpoints
oc describe service user-service

# Verify pods are running and labeled correctly
oc get pods --show-labels
```

### Restart Deployments

```bash
# Restart a single deployment
oc rollout restart deployment/user-service

# Restart all deployments
oc rollout restart deployment/user-service deployment/post-service \
  deployment/comment-service deployment/message-service deployment/frontend
```

### Scale Deployments

```bash
# Scale up
oc scale deployment/post-service --replicas=3

# Scale down
oc scale deployment/post-service --replicas=1

# Scale to zero (stop)
oc scale deployment/post-service --replicas=0
```

---

## 7. Cleanup

### Delete Individual Resources

```bash
# Delete a specific deployment
oc delete deployment/frontend

# Delete a specific service
oc delete service/frontend

# Delete a specific route
oc delete route/frontend
```

### Delete All Application Resources

```bash
# Delete all resources by label (if labeled)
oc delete all -l app=social-media

# Delete all application resources
oc delete deployment --all
oc delete service --all
oc delete route --all
oc delete buildconfig --all
oc delete imagestream --all
```

### Delete the Entire Project

```bash
# WARNING: This deletes everything including the database!
oc delete project social-media-app
```

---

## Appendix: Complete OpenShift Manifest Files

### BuildConfigs + ImageStreams Summary

```yaml
# openshift/buildconfigs.yaml
# Creates ImageStreams and BuildConfigs for each service
# Source: GitHub repository
# Strategy: Docker build
# Trigger: ConfigChange (auto-build on changes)
```

### Deployments Summary

```yaml
# openshift/deployments.yaml
# Creates Deployment for each service
# Uses images from internal registry
# Ports: 3001 (user), 3002 (post), 3003 (comment), 3004 (message), 3000 (frontend)
```

### Services Summary

```yaml
# openshift/services.yaml
# Creates ClusterIP Services for internal communication
# Maps service names to deployment pods
```

### Routes Summary

```yaml
# openshift/routes.yaml
# Creates Route for frontend (external access)
# Automatically gets an OpenShift domain
```

---

## Quick Reference Commands

```bash
# Login
oc login --token=XXX --server=https://api.xxx:6443

# Switch project
oc project social-media-app

# Check status
oc status

# Get all resources
oc get all

# View pod logs
oc logs <pod-name>

# Execute command in pod
oc exec -it <pod-name> -- /bin/bash

# Port forward (local testing)
oc port-forward service/user-service 3001:3001

# Get route URL
oc get route frontend -o jsonpath='{.spec.host}'
```

---

**Happy Deploying! 🚀**
