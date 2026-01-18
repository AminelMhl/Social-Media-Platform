# Social Media Microservices Platform

A Reddit-like social media application built with a **microservices architecture**, designed for deployment on **Red Hat OpenShift** (Kubernetes).

**Course:** IT460 - Cloud Computing

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Technology Stack](#-technology-stack)
- [Prerequisites](#-prerequisites)
- [Local Development (Docker Compose)](#-local-development-docker-compose)
- [OpenShift Deployment](#-openshift-deployment)
- [API Reference](#-api-reference)
- [Frontend Pages](#-frontend-pages)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Documentation](#-documentation)

---

## 🎯 Overview

This project implements a social media platform using microservices, demonstrating cloud-native architecture patterns including:

- **Containerization** with Docker
- **Container Orchestration** with Kubernetes/OpenShift
- **Microservices Communication** via REST APIs
- **Stateless Authentication** with JWT
- **Persistent Storage** with PostgreSQL

---

## 🏗 Architecture

```
                    ┌─────────────────┐
                    │  OpenShift      │
                    │  Route (HTTPS)  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    Frontend     │
                    │   (Next.js)     │
                    │   Port: 3000    │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ User Service  │  │ Post Service  │  │Comment Service│
│  Port: 3001   │  │  Port: 3002   │  │  Port: 3003   │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │
        │          ┌───────▼───────┐          │
        │          │Message Service│          │
        │          │  Port: 3004   │          │
        │          └───────┬───────┘          │
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                  ┌────────▼────────┐
                  │   PostgreSQL    │
                  │   Port: 5432    │
                  └─────────────────┘
```

### Services

| Service | Port | Description |
|---------|------|-------------|
| `user-service` | 3001 | User signup, login, profile management (JWT auth) |
| `post-service` | 3002 | CRUD for posts, voting system |
| `comment-service` | 3003 | CRUD for comments, reactions |
| `message-service` | 3004 | Direct messages between users |
| `frontend` | 3000 | Next.js React application |
| `db` | 5432 | PostgreSQL database (shared) |

---

## ✨ Features

- ✅ User registration & JWT authentication
- ✅ Create, edit, delete posts
- ✅ Reddit-style upvote/downvote system
- ✅ Comment on posts with reactions
- ✅ Direct messaging between users
- ✅ User profiles with customization
- ✅ Reddit-inspired dark theme UI

---

## 🛠 Technology Stack

| Component | Technology |
|-----------|------------|
| **Backend** | NestJS (Node.js + TypeScript) |
| **Frontend** | Next.js (React + TypeScript) |
| **Database** | PostgreSQL 16 |
| **ORM** | TypeORM |
| **Auth** | JWT + Passport.js + bcrypt |
| **Containers** | Docker |
| **Local Dev** | Docker Compose |
| **Production** | OpenShift (Kubernetes) |

---

## ✅ Prerequisites

### For Local Development
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Docker Compose](https://docs.docker.com/compose/) (included with Docker Desktop)
- Git

### For OpenShift Deployment
- [OpenShift CLI (`oc`)](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/)
- Access to an OpenShift cluster:
  - [Red Hat Developer Sandbox](https://developers.redhat.com/developer-sandbox) (Free)
  - OR enterprise OpenShift cluster

---

## 🐳 Local Development (Docker Compose)

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/AminelMhl/Social-Media-Platform.git
cd Social-Media-Platform

# 2. Start all services
docker compose up --build

# 3. Access the application
# Frontend: http://localhost:3000
```

### Service URLs (Local)

| Service | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| User Service | http://localhost:3001 |
| Post Service | http://localhost:3002 |
| Comment Service | http://localhost:3003 |
| Message Service | http://localhost:3004 |
| PostgreSQL | localhost:5433 |

### Development Commands

```bash
# Start all services
docker compose up --build

# Start in detached mode
docker compose up -d

# View logs
docker compose logs -f

# Stop all services
docker compose down

# Stop and remove volumes (reset database)
docker compose down -v

# Rebuild a specific service
docker compose build user-service
docker compose up user-service
```

### Development Without Docker

```bash
# Start only the database
docker compose up db -d

# Install dependencies for each service
cd user-service && npm install
cd ../post-service && npm install
cd ../comment-service && npm install
cd ../message-service && npm install
cd ../frontend && npm install

# Start each service (in separate terminals)
cd user-service && npm run start:dev
cd post-service && npm run start:dev
cd comment-service && npm run start:dev
cd message-service && npm run start:dev
cd frontend && npm run dev
```

---

## ☸️ OpenShift Deployment

### Quick Start

```bash
# 1. Login to OpenShift (get token from web console)
oc login --token=sha256~YOUR_TOKEN --server=https://api.YOUR_CLUSTER:6443

# 2. Run the deployment script
chmod +x deploy-openshift.sh
./deploy-openshift.sh
```

### Step-by-Step Deployment

#### Step 1: Login to OpenShift

```bash
# Get your token from the OpenShift web console:
# Click username (top right) → Copy login command → Display Token

oc login --token=sha256~XXXXX --server=https://api.cluster.example.com:6443
oc whoami  # Verify login
```

#### Step 2: Create Project

```bash
oc new-project social-media-app
```

#### Step 3: Deploy PostgreSQL

```bash
oc new-app postgresql-persistent \
  --param POSTGRESQL_USER=social_user \
  --param POSTGRESQL_PASSWORD=social_pass \
  --param POSTGRESQL_DATABASE=social_db \
  --param VOLUME_CAPACITY=1Gi

# Wait for database
oc get pods -w
```

#### Step 4: Apply Manifests

```bash
oc apply -f openshift/buildconfigs.yaml
oc apply -f openshift/deployments.yaml
oc apply -f openshift/services.yaml
oc apply -f openshift/routes.yaml
```

#### Step 5: Start Builds

```bash
oc start-build user-service
oc start-build post-service
oc start-build comment-service
oc start-build message-service
oc start-build frontend

# Watch progress
oc get builds -w
```

#### Step 6: Configure Environment Variables

```bash
# User Service
oc set env deployment/user-service \
  DB_HOST=postgresql DB_PORT=5432 \
  DB_USER=social_user DB_PASSWORD=social_pass DB_NAME=social_db \
  JWT_SECRET=your-secret-key JWT_EXPIRES_IN=1d

# Post Service
oc set env deployment/post-service \
  DB_HOST=postgresql DB_PORT=5432 \
  DB_USER=social_user DB_PASSWORD=social_pass DB_NAME=social_db \
  USER_SERVICE_URL=http://user-service:3001

# Comment Service
oc set env deployment/comment-service \
  DB_HOST=postgresql DB_PORT=5432 \
  DB_USER=social_user DB_PASSWORD=social_pass DB_NAME=social_db \
  USER_SERVICE_URL=http://user-service:3001 \
  POST_SERVICE_URL=http://post-service:3002

# Message Service
oc set env deployment/message-service \
  DB_HOST=postgresql DB_PORT=5432 \
  DB_USER=social_user DB_PASSWORD=social_pass DB_NAME=social_db \
  JWT_SECRET=your-secret-key \
  USER_SERVICE_URL=http://user-service:3001

# Frontend
oc set env deployment/frontend \
  NEXT_PUBLIC_USER_SERVICE_URL=http://user-service:3001 \
  NEXT_PUBLIC_POST_SERVICE_URL=http://post-service:3002 \
  NEXT_PUBLIC_COMMENT_SERVICE_URL=http://comment-service:3003 \
  NEXT_PUBLIC_MESSAGE_SERVICE_URL=http://message-service:3004
```

#### Step 7: Get Application URL

```bash
echo "https://$(oc get route frontend -o jsonpath='{.spec.host}')"
```

### OpenShift Quick Reference

```bash
# View all resources
oc get all

# View pods
oc get pods

# View logs
oc logs deployment/<service-name>

# Restart deployment
oc rollout restart deployment/<name>

# Scale deployment
oc scale deployment/<name> --replicas=3

# Delete project
oc delete project social-media-app
```

---

## 📡 API Reference

### User Service (Port 3001)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/signup` | Create account, receive JWT | No |
| POST | `/auth/login` | Login, receive JWT | No |
| GET | `/profile` | Get current user profile | Yes |
| PUT | `/profile` | Update profile | Yes |
| GET | `/users/:id` | Get public user profile | No |

### Post Service (Port 3002)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/posts` | List all posts | No |
| POST | `/posts` | Create post | Yes |
| GET | `/posts/:id` | Get single post | No |
| PUT | `/posts/:id` | Update post | Yes |
| DELETE | `/posts/:id` | Delete post | Yes |
| POST | `/posts/:id/like` | Upvote post | Yes |
| POST | `/posts/:id/dislike` | Downvote post | Yes |
| DELETE | `/posts/:id/reaction` | Remove vote | Yes |

### Comment Service (Port 3003)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/comments` | Create comment | Yes |
| GET | `/comments/post/:postId` | Get comments for post | No |
| POST | `/comments/:id/like` | Upvote comment | Yes |
| POST | `/comments/:id/dislike` | Downvote comment | Yes |
| DELETE | `/comments/:id` | Delete comment | Yes |

### Message Service (Port 3004)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/messages` | Send message | Yes |
| GET | `/messages/conversation/:userId` | Get conversation | Yes |

### Authentication

Include JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

---

## 📱 Frontend Pages

| Route | Description |
|-------|-------------|
| `/` | Landing page |
| `/signup` | User registration |
| `/login` | User login |
| `/feed` | View/create posts and comments |
| `/profile` | View/edit current user profile |
| `/users/[id]` | View public profile of another user |
| `/messages/[id]` | Direct messages with another user |

---

## ⚙️ Configuration

### Environment Variables

**Backend Services:**
```env
NODE_ENV=development
PORT=3001
DB_HOST=localhost
DB_PORT=5432
DB_USER=social_user
DB_PASSWORD=social_pass
DB_NAME=social_db
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=1d
USER_SERVICE_URL=http://user-service:3001
POST_SERVICE_URL=http://post-service:3002
```

**Frontend:**
```env
NEXT_PUBLIC_USER_SERVICE_URL=http://localhost:3001
NEXT_PUBLIC_POST_SERVICE_URL=http://localhost:3002
NEXT_PUBLIC_COMMENT_SERVICE_URL=http://localhost:3003
NEXT_PUBLIC_MESSAGE_SERVICE_URL=http://localhost:3004
```

---

## 🔧 Troubleshooting

### Local Development

**Database connection failed:**
```bash
# Ensure PostgreSQL is running
docker compose ps

# Check database logs
docker compose logs db
```

**Port already in use:**
```bash
# Find process using port
netstat -ano | findstr :3001  # Windows
lsof -i :3001                  # Linux/Mac

# Stop conflicting process or change port in docker-compose.yml
```

### OpenShift Deployment

**Build fails:**
```bash
oc logs build/user-service-1
```

**Pod CrashLoopBackOff:**
```bash
oc logs <pod-name>
oc get events --sort-by=.lastTimestamp
```

**Service not found (503 error):**
```bash
oc get service user-service
oc describe endpoints user-service
```

**Restart all services:**
```bash
oc rollout restart deployment/user-service \
  deployment/post-service \
  deployment/comment-service \
  deployment/message-service \
  deployment/frontend
```

---

## 📚 Documentation

For detailed documentation, see the `docs/` folder:

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Complete system architecture |
| [API_REFERENCE.md](docs/API_REFERENCE.md) | Detailed API documentation |
| [DESIGN_DECISIONS.md](docs/DESIGN_DECISIONS.md) | Technical decision rationale |
| [OPENSHIFT_DEPLOYMENT.md](docs/OPENSHIFT_DEPLOYMENT.md) | Detailed OpenShift guide |

---

## 📁 Project Structure

```
Social-Media-Platform/
├── user-service/          # Authentication & user management
├── post-service/          # Posts & voting
├── comment-service/       # Comments & reactions
├── message-service/       # Direct messaging
├── frontend/              # Next.js React app
├── openshift/             # Kubernetes/OpenShift manifests
│   ├── buildconfigs.yaml
│   ├── deployments.yaml
│   ├── services.yaml
│   └── routes.yaml
├── docs/                  # Documentation
├── docker-compose.yml     # Local development
├── deploy-openshift.sh    # Deployment script
└── README.md              # This file
```

---

## 📄 License

This project is created for educational purposes as part of the IT460 Cloud Computing course.

---

**Course:** IT460 - Cloud Computing  
**Platform:** Red Hat OpenShift (Kubernetes)
