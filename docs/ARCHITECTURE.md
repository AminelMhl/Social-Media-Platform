# Social Media Microservices Platform - Architecture Documentation

## IT460 Cloud Computing Course Project

**Project Title:** Social Media Microservices Platform  
**Course:** IT460 - Cloud Computing  
**Deployment Platform:** OpenShift (Red Hat Kubernetes)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Microservices Design](#3-microservices-design)
4. [Technology Stack](#4-technology-stack)
5. [Database Design](#5-database-design)
6. [API Design & Communication](#6-api-design--communication)
7. [Authentication & Authorization](#7-authentication--authorization)
8. [Frontend Architecture](#8-frontend-architecture)
9. [Design Decisions & Rationale](#9-design-decisions--rationale)
10. [OpenShift Deployment Guide](#10-openshift-deployment-guide)
11. [Local Development Setup](#11-local-development-setup)
12. [Security Considerations](#12-security-considerations)
13. [Scalability & Future Improvements](#13-scalability--future-improvements)

---

## 1. Executive Summary

This project implements a **Reddit-like social media platform** using a microservices architecture. The application allows users to:

- **Register and authenticate** with secure JWT-based sessions
- **Create, read, update, and delete posts** with voting functionality
- **Comment on posts** with nested discussions and reactions
- **Send direct messages** to other users
- **View user profiles** with customizable display information

The platform is designed for cloud-native deployment on **OpenShift** (Red Hat's enterprise Kubernetes distribution), demonstrating modern cloud computing principles including containerization, orchestration, and microservices patterns.

---

## 2. System Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              OPENSHIFT CLUSTER                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    ┌──────────────────┐                                                     │
│    │   OpenShift      │    HTTPS                                            │
│    │   Route          │◄─────────────── Internet Users                      │
│    └────────┬─────────┘                                                     │
│             │                                                                │
│             ▼                                                                │
│    ┌──────────────────┐                                                     │
│    │    Frontend      │                                                     │
│    │   (Next.js)      │                                                     │
│    │   Port: 3000     │                                                     │
│    └────────┬─────────┘                                                     │
│             │                                                                │
│             │ REST API Calls                                                 │
│             ▼                                                                │
│    ┌────────────────────────────────────────────────────────────────┐       │
│    │                    Backend Microservices                        │       │
│    ├────────────────┬────────────────┬────────────────┬─────────────┤       │
│    │                │                │                │             │       │
│    │  User Service  │  Post Service  │Comment Service │Msg Service  │       │
│    │  Port: 3001    │  Port: 3002    │  Port: 3003    │ Port: 3004  │       │
│    │                │                │                │             │       │
│    │  • Auth        │  • CRUD Posts  │  • Comments    │ • Direct    │       │
│    │  • Profiles    │  • Voting      │  • Reactions   │   Messages  │       │
│    │  • JWT         │  • Reactions   │  • Threads     │ • Inbox     │       │
│    │                │                │                │             │       │
│    └───────┬────────┴───────┬────────┴───────┬────────┴──────┬──────┘       │
│            │                │                │               │               │
│            └────────────────┴───────┬────────┴───────────────┘               │
│                                     │                                        │
│                                     ▼                                        │
│                          ┌──────────────────┐                               │
│                          │   PostgreSQL     │                               │
│                          │   Database       │                               │
│                          │   Port: 5432     │                               │
│                          └──────────────────┘                               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Service Communication Flow

```
┌──────────┐    ┌──────────────┐    ┌───────────────┐    ┌────────────────┐
│ Frontend │───►│ User Service │◄───│ Post Service  │◄───│ Comment Service│
└──────────┘    └──────────────┘    └───────────────┘    └────────────────┘
     │                 ▲                    ▲                     │
     │                 │                    │                     │
     ▼                 │                    └─────────────────────┘
┌──────────────────────┘
│ Message Service │
└─────────────────┘
```

---

## 3. Microservices Design

### 3.1 User Service (Port 3001)

**Responsibility:** Handles all user-related operations including authentication, registration, and profile management.

**Endpoints:**
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/signup` | User registration | No |
| POST | `/auth/login` | User authentication | No |
| GET | `/profile` | Get current user profile | Yes |
| PUT | `/profile` | Update user profile | Yes |
| GET | `/users/:id` | Get public user profile | No |
| GET | `/users/internal/:id` | Internal user lookup | Internal |

**Key Features:**
- Password hashing with bcrypt
- JWT token generation and validation
- Profile image URL support
- Bio and display name customization

---

### 3.2 Post Service (Port 3002)

**Responsibility:** Manages post creation, retrieval, voting, and lifecycle.

**Endpoints:**
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/posts` | List all posts | No |
| POST | `/posts` | Create new post | Yes |
| GET | `/posts/:id` | Get single post | No |
| PUT | `/posts/:id` | Update post | Yes (owner) |
| DELETE | `/posts/:id` | Delete post | Yes (owner) |
| POST | `/posts/:id/like` | Upvote post | Yes |
| POST | `/posts/:id/dislike` | Downvote post | Yes |
| DELETE | `/posts/:id/reaction` | Remove vote | Yes |

**Key Features:**
- Reddit-style upvote/downvote system
- Author information enrichment (calls User Service)
- Score calculation (likes - dislikes)
- Ownership validation for modifications

---

### 3.3 Comment Service (Port 3003)

**Responsibility:** Handles comment creation, threading, and reactions.

**Endpoints:**
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/comments` | Create comment | Yes |
| GET | `/comments/post/:postId` | Get comments for post | No |
| POST | `/comments/:id/like` | Upvote comment | Yes |
| POST | `/comments/:id/dislike` | Downvote comment | Yes |
| DELETE | `/comments/:id/reaction` | Remove reaction | Yes |
| DELETE | `/comments/:id` | Delete comment | Yes (owner) |

**Key Features:**
- Post-comment relationship
- Voting/reaction system
- Author information enrichment
- Cascading relationship with posts

---

### 3.4 Message Service (Port 3004)

**Responsibility:** Enables direct messaging between users.

**Endpoints:**
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/messages` | Send message | Yes |
| GET | `/messages/conversation/:userId` | Get conversation | Yes |

**Key Features:**
- User-to-user private messaging
- Conversation threading
- Chronological message ordering
- Sender/receiver validation

---

### 3.5 Frontend Service (Port 3000)

**Responsibility:** Server-side rendered React application providing the user interface.

**Pages:**
| Route | Description |
|-------|-------------|
| `/` | Landing/home page |
| `/login` | User login form |
| `/signup` | User registration form |
| `/feed` | Main post feed with comments |
| `/profile` | Current user's profile (edit) |
| `/users/:id` | Public user profile view |
| `/messages/:id` | Direct message conversation |

---

## 4. Technology Stack

### Backend Services

| Technology | Version | Purpose |
|------------|---------|---------|
| **NestJS** | 10.x | Node.js framework for building scalable server-side applications |
| **TypeScript** | 5.x | Type-safe JavaScript for improved developer experience |
| **TypeORM** | 0.3.x | Object-Relational Mapping for database operations |
| **PostgreSQL** | 16.x | Relational database for data persistence |
| **Passport.js** | 0.7.x | Authentication middleware |
| **JWT** | - | JSON Web Tokens for stateless authentication |
| **bcrypt** | - | Password hashing library |

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| **Next.js** | 14.x | React framework with SSR/SSG capabilities |
| **React** | 18.x | UI component library |
| **TypeScript** | 5.x | Type-safe development |
| **CSS3** | - | Reddit-inspired dark theme styling |

### DevOps & Infrastructure

| Technology | Purpose |
|------------|---------|
| **Docker** | Containerization of all services |
| **Docker Compose** | Local development orchestration |
| **OpenShift** | Production container orchestration (Kubernetes) |
| **GitHub** | Source code management & CI/CD triggers |

---

## 5. Database Design

### Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│      User       │       │      Post       │       │    Comment      │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │◄──────│ authorId (FK)   │       │ id (PK)         │
│ email           │       │ id (PK)         │◄──────│ postId (FK)     │
│ password        │       │ title           │       │ authorId (FK)   │
│ displayName     │       │ content         │       │ content         │
│ bio             │       │ createdAt       │       │ createdAt       │
│ profileImageUrl │       │ updatedAt       │       │ updatedAt       │
│ createdAt       │       └─────────────────┘       └─────────────────┘
│ updatedAt       │               │                         │
└─────────────────┘               │                         │
        │                         ▼                         ▼
        │               ┌─────────────────┐       ┌─────────────────┐
        │               │  PostReaction   │       │CommentReaction  │
        │               ├─────────────────┤       ├─────────────────┤
        └──────────────►│ id (PK)         │       │ id (PK)         │
                        │ postId (FK)     │       │ commentId (FK)  │
                        │ userId (FK)     │◄──────│ userId (FK)     │
                        │ type (like/     │       │ type            │
                        │       dislike)  │       │                 │
                        └─────────────────┘       └─────────────────┘

┌─────────────────┐
│    Message      │
├─────────────────┤
│ id (PK)         │
│ senderId (FK)   │───────► User
│ receiverId (FK) │───────► User
│ content         │
│ createdAt       │
└─────────────────┘
```

### Database Configuration

All services share a single PostgreSQL instance:
- **Host:** `db` (Docker) / configured via environment
- **Port:** `5432`
- **Database:** `social_db`
- **User:** `social_user`

---

## 6. API Design & Communication

### Inter-Service Communication

Services communicate via **synchronous REST API calls** over HTTP:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Service Communication Matrix                  │
├─────────────────┬────────────────────┬──────────────────────────┤
│ Calling Service │ Called Service     │ Purpose                  │
├─────────────────┼────────────────────┼──────────────────────────┤
│ Post Service    │ User Service       │ Fetch author info        │
│ Comment Service │ User Service       │ Fetch commenter info     │
│ Comment Service │ Post Service       │ Validate post exists     │
│ Message Service │ User Service       │ Validate users exist     │
│ Frontend        │ All Backend Services│ User interactions       │
└─────────────────┴────────────────────┴──────────────────────────┘
```

### API Response Format

All API responses follow a consistent JSON structure:

```json
// Success Response
{
  "id": "uuid",
  "property": "value",
  "createdAt": "2024-01-01T00:00:00.000Z"
}

// Error Response
{
  "statusCode": 400,
  "message": "Error description",
  "error": "Bad Request"
}
```

---

## 7. Authentication & Authorization

### JWT-Based Authentication Flow

```
┌────────┐          ┌──────────────┐          ┌──────────────┐
│ Client │          │   Frontend   │          │ User Service │
└───┬────┘          └──────┬───────┘          └──────┬───────┘
    │                      │                         │
    │ 1. Login Request     │                         │
    │─────────────────────►│                         │
    │                      │ 2. POST /auth/login     │
    │                      │────────────────────────►│
    │                      │                         │
    │                      │ 3. Validate Credentials │
    │                      │                         │
    │                      │ 4. Return JWT Token     │
    │                      │◄────────────────────────│
    │ 5. Store Token       │                         │
    │◄─────────────────────│                         │
    │                      │                         │
    │ 6. Authenticated Request (Bearer Token)        │
    │─────────────────────►│                         │
    │                      │ 7. Validate JWT         │
    │                      │────────────────────────►│
    │                      │                         │
    │                      │ 8. Token Valid          │
    │                      │◄────────────────────────│
    │ 9. Response          │                         │
    │◄─────────────────────│                         │
```

### Security Implementation

| Feature | Implementation |
|---------|----------------|
| Password Storage | bcrypt hashing (10 rounds) |
| Token Type | JWT (JSON Web Token) |
| Token Expiry | Configurable (default: 1 day) |
| Route Protection | NestJS Guards (`@UseGuards(JwtAuthGuard)`) |
| Secret Management | Environment variables |

---

## 8. Frontend Architecture

### Component Structure

```
frontend/
├── pages/
│   ├── _app.tsx          # App wrapper, global CSS import
│   ├── index.tsx         # Landing page
│   ├── login.tsx         # Login form
│   ├── signup.tsx        # Registration form
│   ├── feed.tsx          # Main post feed
│   ├── profile.tsx       # User profile (self)
│   ├── users/
│   │   └── [id].tsx      # Public profile view
│   └── messages/
│       └── [id].tsx      # Direct messages
├── styles/
│   ├── globals.css       # Reddit-inspired dark theme
│   └── globals.d.ts      # TypeScript declarations
└── public/               # Static assets
```

### Styling System (Reddit-Inspired Dark Theme)

**CSS Variables:**
```css
:root {
  --primary-color: #ff4500;      /* Reddit orange */
  --background-color: #1a1a1b;   /* Dark background */
  --surface-color: #272729;      /* Card/surface color */
  --text-primary: #d7dadc;       /* Primary text */
  --text-secondary: #818384;     /* Secondary text */
  --border-color: #343536;       /* Borders */
  --upvote-color: #ff4500;       /* Upvote orange */
  --downvote-color: #7193ff;     /* Downvote blue */
}
```

**Key Components:**
- `.navbar` - Top navigation bar
- `.post` - Post card with vote column
- `.comment` - Comment with reactions
- `.form-container` - Auth forms styling
- `.card` - Generic card component
- `.btn`, `.btn-primary` - Button styles

---

## 9. Design Decisions & Rationale

### 9.1 Microservices Architecture

**Decision:** Split the application into 4 backend services + 1 frontend.

**Rationale:**
- **Scalability:** Each service can be scaled independently based on load
- **Maintainability:** Smaller codebases are easier to understand and modify
- **Technology Flexibility:** Services can evolve independently
- **Team Autonomy:** Different teams can own different services
- **Fault Isolation:** Failure in one service doesn't crash the entire system

### 9.2 NestJS for Backend

**Decision:** Use NestJS framework for all backend services.

**Rationale:**
- **TypeScript Native:** Built-in TypeScript support for type safety
- **Modular Architecture:** Encourages clean, organized code structure
- **Dependency Injection:** Built-in DI container for testability
- **Decorators:** Express-like simplicity with Angular-like patterns
- **Rich Ecosystem:** Guards, pipes, interceptors for cross-cutting concerns

### 9.3 Shared Database

**Decision:** All services share a single PostgreSQL instance.

**Rationale:**
- **Simplicity:** Reduces operational complexity for a course project
- **Cost Efficiency:** Single database instance is more economical
- **Data Consistency:** No eventual consistency issues
- **Trade-off Acknowledged:** In production, consider database-per-service pattern

### 9.4 JWT Authentication

**Decision:** Stateless JWT-based authentication.

**Rationale:**
- **Scalability:** No server-side session storage needed
- **Microservices Friendly:** Token can be validated by any service
- **Performance:** No database lookup for every authenticated request
- **Cross-Service:** Token works across all microservices

### 9.5 Synchronous REST Communication

**Decision:** Services communicate via REST APIs (not message queues).

**Rationale:**
- **Simplicity:** Easier to implement and debug
- **Immediate Consistency:** Responses are synchronous
- **Course Scope:** Appropriate complexity for IT460
- **Future Enhancement:** Can add message queues later if needed

### 9.6 Server-Side Rendering (Next.js)

**Decision:** Use Next.js for the frontend instead of Create React App.

**Rationale:**
- **SEO Benefits:** Server-rendered pages are indexable
- **Performance:** Faster initial page loads
- **API Routes:** Built-in API endpoint capability if needed
- **Production Ready:** Optimized builds out of the box

---

## 10. OpenShift Deployment Guide

### 10.1 Prerequisites

Before deploying, ensure you have:

1. **OpenShift CLI (`oc`)** installed and configured
2. **Access to an OpenShift cluster** (Red Hat Developer Sandbox or enterprise cluster)
3. **GitHub repository** with your source code
4. **PostgreSQL database** accessible from the cluster

### 10.2 Project Setup

```bash
# Login to OpenShift
oc login --token=<your-token> --server=<cluster-url>

# Create a new project (namespace)
oc new-project social-media-app

# Verify project creation
oc project
```

### 10.3 Database Deployment

**Option A: Deploy PostgreSQL on OpenShift**

```bash
# Deploy PostgreSQL using the official template
oc new-app postgresql-persistent \
  --param POSTGRESQL_USER=social_user \
  --param POSTGRESQL_PASSWORD=social_pass \
  --param POSTGRESQL_DATABASE=social_db \
  --param VOLUME_CAPACITY=1Gi

# Wait for the database to be ready
oc get pods -w
```

**Option B: Use External Database**

Create a secret for external database credentials:

```bash
oc create secret generic db-credentials \
  --from-literal=DB_HOST=<external-db-host> \
  --from-literal=DB_PORT=5432 \
  --from-literal=DB_USER=social_user \
  --from-literal=DB_PASSWORD=social_pass \
  --from-literal=DB_NAME=social_db
```

### 10.4 Create Secrets

```bash
# Create JWT secret
oc create secret generic jwt-secret \
  --from-literal=JWT_SECRET=your-super-secret-jwt-key \
  --from-literal=JWT_EXPIRES_IN=1d
```

### 10.5 Apply Kubernetes Manifests

Deploy all resources in order:

```bash
# Navigate to openshift directory
cd openshift/

# 1. Create ImageStreams and BuildConfigs
oc apply -f buildconfigs.yaml

# 2. Start builds for all services
oc start-build user-service
oc start-build post-service
oc start-build comment-service
oc start-build message-service
oc start-build frontend

# 3. Wait for builds to complete
oc get builds -w

# 4. Create Deployments (after builds complete)
oc apply -f deployments.yaml

# 5. Create Services
oc apply -f services.yaml

# 6. Create Routes
oc apply -f routes.yaml
```

### 10.6 Configure Environment Variables

Update deployments with proper environment variables:

```bash
# User Service
oc set env deployment/user-service \
  DB_HOST=postgresql \
  DB_PORT=5432 \
  DB_USER=social_user \
  DB_PASSWORD=social_pass \
  DB_NAME=social_db \
  JWT_SECRET=your-super-secret-jwt-key \
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
  JWT_SECRET=your-super-secret-jwt-key \
  USER_SERVICE_URL=http://user-service:3001

# Frontend
oc set env deployment/frontend \
  NEXT_PUBLIC_USER_SERVICE_URL=http://user-service:3001 \
  NEXT_PUBLIC_POST_SERVICE_URL=http://post-service:3002 \
  NEXT_PUBLIC_COMMENT_SERVICE_URL=http://comment-service:3003 \
  NEXT_PUBLIC_MESSAGE_SERVICE_URL=http://message-service:3004
```

### 10.7 Verify Deployment

```bash
# Check all pods are running
oc get pods

# Check services
oc get services

# Get the application URL
oc get routes

# View logs if issues arise
oc logs deployment/user-service
oc logs deployment/frontend
```

### 10.8 OpenShift Resource Summary

| Resource Type | Name | Purpose |
|--------------|------|---------|
| **ImageStream** | user-service, post-service, comment-service, message-service, frontend | Container image storage |
| **BuildConfig** | (same as above) | Build from GitHub source |
| **Deployment** | (same as above) | Pod management |
| **Service** | (same as above) | Internal networking |
| **Route** | frontend | External access |

### 10.9 Webhook Configuration (CI/CD)

To enable automatic builds on git push:

1. Get the webhook URL:
```bash
oc describe bc/user-service | grep -A 1 "Webhook Generic"
```

2. Add the webhook URL to your GitHub repository:
   - Go to Settings → Webhooks → Add webhook
   - Paste the URL
   - Set Content type to `application/json`
   - Select "Just the push event"

---

## 11. Local Development Setup

### 11.1 Prerequisites

- Docker Desktop
- Docker Compose
- Node.js 18+ (for local development without Docker)
- Git

### 11.2 Quick Start with Docker Compose

```bash
# Clone the repository
git clone https://github.com/AminelMhl/Social-Media-Platform.git
cd Social-Media-Platform

# Start all services
docker compose up --build

# Access the application
# Frontend: http://localhost:3000
# User Service: http://localhost:3001
# Post Service: http://localhost:3002
# Comment Service: http://localhost:3003
# Message Service: http://localhost:3004
```

### 11.3 Development without Docker

```bash
# Start PostgreSQL (can use Docker for just the database)
docker compose up db -d

# Install dependencies for each service
cd user-service && npm install
cd ../post-service && npm install
cd ../comment-service && npm install
cd ../message-service && npm install
cd ../frontend && npm install

# Start each service (in separate terminals)
# Terminal 1: User Service
cd user-service && npm run start:dev

# Terminal 2: Post Service
cd post-service && npm run start:dev

# Terminal 3: Comment Service
cd comment-service && npm run start:dev

# Terminal 4: Message Service
cd message-service && npm run start:dev

# Terminal 5: Frontend
cd frontend && npm run dev
```

### 11.4 Environment Variables

Create `.env` files in each service directory based on `.env.example`:

**user-service/.env:**
```
NODE_ENV=development
PORT=3001
DB_HOST=localhost
DB_PORT=5433
DB_USER=social_user
DB_PASSWORD=social_pass
DB_NAME=social_db
JWT_SECRET=supersecretjwt
JWT_EXPIRES_IN=1d
```

---

## 12. Security Considerations

### Current Implementation

| Security Measure | Status | Description |
|-----------------|--------|-------------|
| Password Hashing | ✅ | bcrypt with salt rounds |
| JWT Authentication | ✅ | Stateless tokens |
| Route Protection | ✅ | Guards on protected endpoints |
| Input Validation | ✅ | DTO validation with class-validator |
| CORS | ⚠️ | Configured for development |

### Production Recommendations

1. **HTTPS/TLS:** Enforce HTTPS via OpenShift Routes
2. **Secrets Management:** Use OpenShift Secrets or external vault
3. **Rate Limiting:** Add rate limiting middleware
4. **CORS:** Restrict to specific origins
5. **SQL Injection:** Use TypeORM parameterized queries (already implemented)
6. **XSS Prevention:** Sanitize user input on frontend
7. **CSRF Protection:** Implement CSRF tokens for forms

---

## 13. Scalability & Future Improvements

### Horizontal Scaling

```yaml
# Scale a deployment
oc scale deployment/post-service --replicas=3
```

### Recommended Improvements

| Improvement | Description | Priority |
|------------|-------------|----------|
| **Message Queues** | Add RabbitMQ/Kafka for async operations | Medium |
| **Caching** | Add Redis for session and data caching | High |
| **Database per Service** | Separate databases for true microservices | Medium |
| **API Gateway** | Add Kong/Ambassador for routing | Medium |
| **Monitoring** | Prometheus + Grafana for observability | High |
| **Logging** | Centralized logging with ELK stack | High |
| **Health Checks** | Kubernetes liveness/readiness probes | High |
| **CI/CD Pipeline** | GitHub Actions or Jenkins | High |

### Health Check Implementation (Recommended)

Add to each service's main module:
```typescript
@Get('health')
healthCheck() {
  return { status: 'ok', timestamp: new Date().toISOString() };
}
```

Update deployments with probes:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3001
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /health
    port: 3001
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## Appendix A: File Structure

```
Social-Media-Platform/
├── user-service/
│   ├── src/
│   │   ├── main.ts
│   │   ├── modules/
│   │   └── users/
│   │       ├── users.controller.ts
│   │       ├── users.service.ts
│   │       ├── auth.service.ts
│   │       ├── dto/
│   │       └── entities/
│   ├── Dockerfile
│   └── package.json
├── post-service/
│   ├── src/
│   │   ├── main.ts
│   │   ├── posts/
│   │   └── shared/
│   ├── Dockerfile
│   └── package.json
├── comment-service/
│   ├── src/
│   │   ├── main.ts
│   │   ├── comments/
│   │   └── shared/
│   ├── Dockerfile
│   └── package.json
├── message-service/
│   ├── src/
│   │   ├── main.ts
│   │   ├── messages/
│   │   └── shared/
│   ├── Dockerfile
│   └── package.json
├── frontend/
│   ├── pages/
│   ├── styles/
│   ├── Dockerfile
│   └── package.json
├── openshift/
│   ├── buildconfigs.yaml
│   ├── deployments.yaml
│   ├── services.yaml
│   └── routes.yaml
├── docker-compose.yml
└── README.md
```

---

## Appendix B: API Quick Reference

### User Service (Port 3001)
```
POST   /auth/signup       - Register new user
POST   /auth/login        - Authenticate user
GET    /profile           - Get current user (auth)
PUT    /profile           - Update current user (auth)
GET    /users/:id         - Get public profile
```

### Post Service (Port 3002)
```
GET    /posts             - List all posts
POST   /posts             - Create post (auth)
GET    /posts/:id         - Get single post
PUT    /posts/:id         - Update post (auth, owner)
DELETE /posts/:id         - Delete post (auth, owner)
POST   /posts/:id/like    - Upvote (auth)
POST   /posts/:id/dislike - Downvote (auth)
DELETE /posts/:id/reaction- Remove vote (auth)
```

### Comment Service (Port 3003)
```
POST   /comments          - Create comment (auth)
GET    /comments/post/:id - Get comments for post
POST   /comments/:id/like - Upvote comment (auth)
POST   /comments/:id/dislike - Downvote (auth)
DELETE /comments/:id/reaction - Remove vote (auth)
DELETE /comments/:id      - Delete comment (auth, owner)
```

### Message Service (Port 3004)
```
POST   /messages          - Send message (auth)
GET    /messages/conversation/:userId - Get conversation (auth)
```

---

**Document Version:** 1.0  
**Last Updated:** 2024  
**Author:** IT460 Cloud Computing Project Team
