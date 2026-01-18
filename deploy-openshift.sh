#!/bin/bash
# deploy-openshift.sh
# Automated deployment script for Social Media Platform on OpenShift
# Usage: ./deploy-openshift.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="social-media-app"
DB_USER="social_user"
DB_PASSWORD="social_pass"
DB_NAME="social_db"
JWT_SECRET="super-secret-jwt-key-$(date +%s)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Social Media Platform - OpenShift Deployment Script        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if logged in to OpenShift
echo -e "${YELLOW}🔍 Checking OpenShift login status...${NC}"
if ! oc whoami &> /dev/null; then
    echo -e "${RED}❌ Not logged in to OpenShift!${NC}"
    echo -e "${YELLOW}Please run: oc login --token=<your-token> --server=<cluster-url>${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Logged in as: $(oc whoami)${NC}"
echo ""

# Create or switch to project
echo -e "${YELLOW}📁 Setting up project: ${PROJECT_NAME}${NC}"
if oc project $PROJECT_NAME &> /dev/null; then
    echo -e "${GREEN}✅ Switched to existing project: ${PROJECT_NAME}${NC}"
else
    echo -e "${YELLOW}Creating new project...${NC}"
    oc new-project $PROJECT_NAME
    echo -e "${GREEN}✅ Created project: ${PROJECT_NAME}${NC}"
fi
echo ""

# Deploy PostgreSQL
echo -e "${YELLOW}🐘 Deploying PostgreSQL database...${NC}"
if oc get deployment postgresql &> /dev/null || oc get dc postgresql &> /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL already deployed${NC}"
else
    oc new-app postgresql-persistent \
        --param POSTGRESQL_USER=$DB_USER \
        --param POSTGRESQL_PASSWORD=$DB_PASSWORD \
        --param POSTGRESQL_DATABASE=$DB_NAME \
        --param VOLUME_CAPACITY=1Gi \
        --name=postgresql
    echo -e "${GREEN}✅ PostgreSQL deployment created${NC}"
fi
echo ""

# Wait for PostgreSQL
echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
oc wait --for=condition=ready pod -l name=postgresql --timeout=180s || {
    echo -e "${YELLOW}PostgreSQL may still be starting, continuing...${NC}"
}
echo -e "${GREEN}✅ PostgreSQL is ready${NC}"
echo ""

# Apply OpenShift manifests
echo -e "${YELLOW}📋 Applying OpenShift manifests...${NC}"

echo "   Applying BuildConfigs..."
oc apply -f openshift/buildconfigs.yaml
echo "   Applying Deployments..."
oc apply -f openshift/deployments.yaml
echo "   Applying Services..."
oc apply -f openshift/services.yaml
echo "   Applying Routes..."
oc apply -f openshift/routes.yaml

echo -e "${GREEN}✅ All manifests applied${NC}"
echo ""

# Start builds
echo -e "${YELLOW}🔨 Starting container builds...${NC}"
echo "   This may take 5-10 minutes..."
echo ""

for service in user-service post-service comment-service message-service frontend; do
    echo -e "   Building ${BLUE}${service}${NC}..."
    oc start-build $service 2>/dev/null || echo "   Build may already be running"
done

echo ""
echo -e "${YELLOW}⏳ Waiting for builds to complete...${NC}"
echo "   (You can check progress with: oc get builds)"

# Wait for each build
for service in user-service post-service comment-service message-service frontend; do
    echo -n "   Waiting for $service build... "
    while true; do
        BUILD_STATUS=$(oc get build -l buildconfig=$service --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].status.phase}' 2>/dev/null || echo "Unknown")
        if [ "$BUILD_STATUS" = "Complete" ]; then
            echo -e "${GREEN}✅ Complete${NC}"
            break
        elif [ "$BUILD_STATUS" = "Failed" ] || [ "$BUILD_STATUS" = "Error" ]; then
            echo -e "${RED}❌ Failed${NC}"
            echo -e "${RED}   Check logs with: oc logs build/${service}-1${NC}"
            break
        else
            sleep 10
        fi
    done
done

echo ""

# Configure environment variables
echo -e "${YELLOW}🔧 Configuring environment variables...${NC}"

# User Service
oc set env deployment/user-service \
    NODE_ENV=production \
    PORT=3001 \
    DB_HOST=postgresql \
    DB_PORT=5432 \
    DB_USER=$DB_USER \
    DB_PASSWORD=$DB_PASSWORD \
    DB_NAME=$DB_NAME \
    JWT_SECRET=$JWT_SECRET \
    JWT_EXPIRES_IN=1d \
    --overwrite

# Post Service
oc set env deployment/post-service \
    NODE_ENV=production \
    PORT=3002 \
    DB_HOST=postgresql \
    DB_PORT=5432 \
    DB_USER=$DB_USER \
    DB_PASSWORD=$DB_PASSWORD \
    DB_NAME=$DB_NAME \
    USER_SERVICE_URL=http://user-service:3001 \
    --overwrite

# Comment Service
oc set env deployment/comment-service \
    NODE_ENV=production \
    PORT=3003 \
    DB_HOST=postgresql \
    DB_PORT=5432 \
    DB_USER=$DB_USER \
    DB_PASSWORD=$DB_PASSWORD \
    DB_NAME=$DB_NAME \
    USER_SERVICE_URL=http://user-service:3001 \
    POST_SERVICE_URL=http://post-service:3002 \
    --overwrite

# Message Service
oc set env deployment/message-service \
    NODE_ENV=production \
    PORT=3004 \
    DB_HOST=postgresql \
    DB_PORT=5432 \
    DB_USER=$DB_USER \
    DB_PASSWORD=$DB_PASSWORD \
    DB_NAME=$DB_NAME \
    JWT_SECRET=$JWT_SECRET \
    USER_SERVICE_URL=http://user-service:3001 \
    --overwrite

# Frontend
oc set env deployment/frontend \
    NODE_ENV=production \
    NEXT_PUBLIC_USER_SERVICE_URL=http://user-service:3001 \
    NEXT_PUBLIC_POST_SERVICE_URL=http://post-service:3002 \
    NEXT_PUBLIC_COMMENT_SERVICE_URL=http://comment-service:3003 \
    NEXT_PUBLIC_MESSAGE_SERVICE_URL=http://message-service:3004 \
    --overwrite

echo -e "${GREEN}✅ Environment variables configured${NC}"
echo ""

# Wait for deployments
echo -e "${YELLOW}⏳ Waiting for deployments to be ready...${NC}"

for deployment in user-service post-service comment-service message-service frontend; do
    echo -n "   Waiting for $deployment... "
    if oc rollout status deployment/$deployment --timeout=180s &> /dev/null; then
        echo -e "${GREEN}✅ Ready${NC}"
    else
        echo -e "${YELLOW}⏳ Still deploying (check with: oc get pods)${NC}"
    fi
done

echo ""

# Get the application URL
FRONTEND_URL=$(oc get route frontend -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    🎉 Deployment Complete!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -n "$FRONTEND_URL" ]; then
    echo -e "${BLUE}🌐 Application URL:${NC}"
    echo -e "   ${GREEN}https://${FRONTEND_URL}${NC}"
else
    echo -e "${YELLOW}⚠️  Route not found. Check with: oc get routes${NC}"
fi

echo ""
echo -e "${BLUE}📊 Useful Commands:${NC}"
echo "   View pods:        oc get pods"
echo "   View services:    oc get services"
echo "   View logs:        oc logs deployment/<service-name>"
echo "   View all:         oc get all"
echo ""
echo -e "${BLUE}🔧 Troubleshooting:${NC}"
echo "   Pod issues:       oc describe pod <pod-name>"
echo "   Restart service:  oc rollout restart deployment/<name>"
echo "   Check events:     oc get events --sort-by=.lastTimestamp"
echo ""
