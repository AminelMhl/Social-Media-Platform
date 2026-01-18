# Design Decisions Document

## Social Media Microservices Platform - IT460

This document explains the key technical decisions made during the development of the Social Media Microservices Platform and the rationale behind each choice.

---

## Table of Contents

1. [Architecture Decisions](#1-architecture-decisions)
2. [Technology Choices](#2-technology-choices)
3. [Database Decisions](#3-database-decisions)
4. [Security Decisions](#4-security-decisions)
5. [Frontend Decisions](#5-frontend-decisions)
6. [Deployment Decisions](#6-deployment-decisions)
7. [Trade-offs & Alternatives Considered](#7-trade-offs--alternatives-considered)

---

## 1. Architecture Decisions

### 1.1 Microservices vs Monolith

**Decision:** Implement as microservices (5 separate services)

**Rationale:**
| Factor | Microservices Benefit |
|--------|----------------------|
| **Course Requirements** | Demonstrates cloud-native architecture patterns |
| **Learning Opportunity** | Exposes students to distributed systems concepts |
| **Scalability Demo** | Shows independent scaling capabilities |
| **Technology Diversity** | Allows different services to evolve independently |

**Trade-offs Accepted:**
- Increased operational complexity
- Network latency between services
- More complex debugging and tracing

**Alternative Considered:** Modular monolith
- Rejected because: Less demonstrative of cloud computing concepts for IT460

---

### 1.2 Service Boundaries

**Decision:** Split into User, Post, Comment, Message, and Frontend services

**Rationale:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    Domain-Driven Service Split                   │
├─────────────────┬───────────────────────────────────────────────┤
│ Service         │ Bounded Context / Responsibility               │
├─────────────────┼───────────────────────────────────────────────┤
│ User Service    │ Identity, Authentication, Profile Management   │
│ Post Service    │ Content Creation, Feed, Post Voting            │
│ Comment Service │ Discussions, Comment Voting, Threading         │
│ Message Service │ Private Communications, Conversations          │
│ Frontend        │ User Interface, Client-Side State              │
└─────────────────┴───────────────────────────────────────────────┘
```

**Key Principle:** Single Responsibility - Each service owns one domain area

---

### 1.3 Synchronous vs Asynchronous Communication

**Decision:** Use synchronous REST API calls for all inter-service communication

**Rationale:**
| Criterion | Synchronous REST | Async Message Queue |
|-----------|-----------------|---------------------|
| Implementation Complexity | ✅ Simple | ❌ Complex |
| Debugging | ✅ Easy to trace | ❌ Harder |
| Immediate Consistency | ✅ Yes | ❌ Eventual |
| Appropriate for Course | ✅ Yes | ❌ Over-engineered |

**Future Enhancement Path:**
```
Current: POST /posts → REST → User Service → Response
Future:  POST /posts → Event Bus → Async Processing → Eventual Response
```

---

## 2. Technology Choices

### 2.1 NestJS for Backend Services

**Decision:** Use NestJS for all backend microservices

**Rationale:**

| Feature | Benefit |
|---------|---------|
| **TypeScript Native** | Compile-time error checking, better IDE support |
| **Modular Architecture** | Controllers, Services, Modules enforce separation |
| **Dependency Injection** | Testable, loosely coupled code |
| **Decorators** | Clean, declarative route definitions |
| **Guards & Pipes** | Built-in auth and validation patterns |
| **NestJS CLI** | Rapid scaffolding of new modules |

**Code Example - Clean Controller Pattern:**
```typescript
@Controller('posts')
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @UseGuards(JwtAuthGuard)  // Declarative auth
  @Post()
  async create(@Req() req: any, @Body() body: CreatePostDto) {
    return this.postsService.create(req.user.sub, body);
  }
}
```

**Alternatives Considered:**
| Framework | Rejection Reason |
|-----------|------------------|
| Express.js | Less structured, no built-in TypeScript support |
| Fastify | Less mature ecosystem for enterprise patterns |
| Spring Boot | Would require Java, different learning curve |

---

### 2.2 Next.js for Frontend

**Decision:** Use Next.js instead of Create React App or plain React

**Rationale:**

| Feature | Benefit |
|---------|---------|
| **Server-Side Rendering** | Better SEO, faster initial page load |
| **File-based Routing** | Simpler than React Router configuration |
| **API Routes** | Built-in backend capability if needed |
| **Production Optimized** | Automatic code splitting, optimization |
| **TypeScript Support** | Native TypeScript integration |

**Trade-offs:**
- More opinionated than plain React
- Larger learning curve for React beginners
- SSR adds complexity for fully client-side apps

---

### 2.3 PostgreSQL for Database

**Decision:** Use PostgreSQL as the database for all services

**Rationale:**

| Criterion | PostgreSQL | MongoDB | MySQL |
|-----------|------------|---------|-------|
| Relational Data | ✅ Excellent | ❌ Poor | ✅ Good |
| JSON Support | ✅ JSONB | ✅ Native | ⚠️ Limited |
| ACID Compliance | ✅ Full | ⚠️ Limited | ✅ Full |
| OpenShift Support | ✅ Official | ✅ Official | ✅ Official |
| TypeORM Compatibility | ✅ Full | ⚠️ Partial | ✅ Full |

**Data Model Fit:**
Our data is inherently relational:
- Users → Posts (1:Many)
- Posts → Comments (1:Many)
- Users → Messages → Users (Many:Many)

---

### 2.4 TypeORM for Database Access

**Decision:** Use TypeORM as the Object-Relational Mapper

**Rationale:**

```typescript
// Clean entity definition
@Entity()
export class Post {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @ManyToOne(() => User)
  author: User;
}
```

| Feature | Benefit |
|---------|---------|
| **Decorators** | Matches NestJS patterns |
| **Migrations** | Schema versioning support |
| **Active Record & Data Mapper** | Flexible patterns |
| **TypeScript** | Full type safety |

---

## 3. Database Decisions

### 3.1 Shared Database Instance

**Decision:** All microservices share a single PostgreSQL instance

**Rationale for Course Project:**

```
┌─────────────────────────────────────────┐
│         Shared Database Model           │
├─────────────────────────────────────────┤
│  ✅ Simpler to operate                  │
│  ✅ Lower resource usage                │
│  ✅ Easier data consistency             │
│  ✅ Appropriate for project scope       │
│  ❌ Services are coupled at DB level    │
│  ❌ Single point of failure             │
└─────────────────────────────────────────┘
```

**Production Recommendation:**
```
┌─────────────────────────────────────────┐
│      Database-per-Service Model         │
├─────────────────────────────────────────┤
│  User Service    → user_db              │
│  Post Service    → post_db              │
│  Comment Service → comment_db           │
│  Message Service → message_db           │
└─────────────────────────────────────────┘
```

---

### 3.2 UUID Primary Keys

**Decision:** Use UUID for all entity primary keys

**Rationale:**
| UUID Benefit | Description |
|--------------|-------------|
| **Global Uniqueness** | No collision across services |
| **No Sequence Contention** | Better performance in distributed systems |
| **Security** | Cannot guess valid IDs |
| **Merge-Friendly** | Easier database migrations |

**Trade-off:** Larger storage size (16 bytes vs 4-8 bytes for integers)

---

## 4. Security Decisions

### 4.1 JWT-Based Authentication

**Decision:** Use stateless JWT tokens for authentication

**Rationale:**

```
┌──────────────────────────────────────────────────────────────┐
│                    JWT Flow                                   │
├──────────────────────────────────────────────────────────────┤
│  1. User logs in → User Service validates credentials        │
│  2. User Service generates JWT → Returns to client           │
│  3. Client stores JWT → Sends in Authorization header        │
│  4. Any service validates JWT → No database lookup needed    │
└──────────────────────────────────────────────────────────────┘
```

| JWT Advantage | Session-Based Alternative |
|---------------|--------------------------|
| ✅ Stateless - scales horizontally | ❌ Requires session store |
| ✅ Cross-service - any service validates | ❌ Session tied to one server |
| ✅ No DB lookup per request | ❌ DB lookup for every request |
| ✅ Mobile-friendly | ❌ Cookie-based, less mobile-friendly |

**Security Measures:**
- Token expiration (1 day default)
- Secret key in environment variable
- HTTPS in production (via OpenShift Routes)

---

### 4.2 Password Hashing

**Decision:** Use bcrypt with 10 salt rounds

**Rationale:**
```typescript
// Secure password storage
const hashedPassword = await bcrypt.hash(password, 10);

// Secure comparison (timing-attack safe)
const isValid = await bcrypt.compare(plaintext, hashedPassword);
```

**Why bcrypt over alternatives:**
| Algorithm | Status |
|-----------|--------|
| bcrypt | ✅ Recommended - intentionally slow |
| Argon2 | ✅ Also good - newer standard |
| SHA256 | ❌ Too fast - vulnerable to brute force |
| MD5 | ❌ Broken - never use for passwords |

---

### 4.3 Route Protection Strategy

**Decision:** Use NestJS Guards for route protection

**Implementation:**
```typescript
// Guard applied at controller method level
@UseGuards(JwtAuthGuard)
@Post()
async create(@Req() req: any, @Body() body: CreatePostDto) {
  const userId = req.user.sub; // Extracted from JWT
  return this.postsService.create(userId, body);
}
```

**Protection Matrix:**
| Endpoint Type | Protection | Example |
|--------------|------------|---------|
| Public Read | None | GET /posts |
| Authenticated Write | JwtAuthGuard | POST /posts |
| Owner Actions | JwtAuthGuard + Service Logic | DELETE /posts/:id |
| Internal Only | Network Policy (K8s) | GET /users/internal/:id |

---

## 5. Frontend Decisions

### 5.1 Reddit-Inspired Dark Theme

**Decision:** Implement a Reddit-like dark theme UI

**Rationale:**
- Familiar UX patterns for social media
- Dark theme reduces eye strain
- Modern, professional appearance
- CSS variables for easy customization

**CSS Variable System:**
```css
:root {
  --primary-color: #ff4500;      /* Reddit orange */
  --background-color: #1a1a1b;   /* Dark background */
  --surface-color: #272729;      /* Card background */
  --text-primary: #d7dadc;       /* Primary text */
  --upvote-color: #ff4500;       /* Upvote orange */
  --downvote-color: #7193ff;     /* Downvote blue */
}
```

---

### 5.2 Component Architecture

**Decision:** Use CSS classes for styling instead of CSS-in-JS

**Rationale:**
| Approach | Chosen? | Reason |
|----------|---------|--------|
| Global CSS + Classes | ✅ Yes | Simple, performant, no runtime cost |
| CSS Modules | ⚠️ Partial | Good for scoping, added later |
| Styled Components | ❌ No | Runtime overhead, learning curve |
| Tailwind CSS | ❌ No | Additional tooling, opinionated |

---

### 5.3 State Management

**Decision:** Use React's built-in useState/useEffect, no Redux

**Rationale:**
- Application state is relatively simple
- Most state is component-local
- Avoids boilerplate of Redux
- Easier to understand and maintain

**Future Enhancement:** Consider Zustand or React Query if state complexity grows

---

## 6. Deployment Decisions

### 6.1 OpenShift over Vanilla Kubernetes

**Decision:** Deploy on OpenShift (Red Hat Kubernetes distribution)

**Rationale:**
| Feature | OpenShift Advantage |
|---------|---------------------|
| **Routes** | Simpler ingress than K8s Ingress |
| **Built-in Registry** | No external registry needed |
| **Source-to-Image (S2I)** | Build from Git in-cluster |
| **Web Console** | User-friendly dashboard |
| **Red Hat Developer Sandbox** | Free tier for students |

---

### 6.2 Docker Multi-Stage Builds

**Decision:** Use multi-stage Dockerfile for smaller images

**Example Pattern:**
```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/main"]
```

**Benefits:**
- Smaller final image (no dev dependencies)
- Faster deployments
- Reduced attack surface

---

### 6.3 Environment-Based Configuration

**Decision:** Use environment variables for all configuration

**Configuration Hierarchy:**
```
1. OpenShift Secrets (sensitive: passwords, JWT secret)
2. OpenShift ConfigMaps (non-sensitive: service URLs)
3. Deployment env vars (overrides)
4. Default values in code (fallbacks)
```

**Example:**
```typescript
// Configuration with fallback
const config = {
  port: process.env.PORT || 3001,
  dbHost: process.env.DB_HOST || 'localhost',
  jwtSecret: process.env.JWT_SECRET, // Required, no default
};
```

---

## 7. Trade-offs & Alternatives Considered

### Summary of Key Trade-offs

| Decision | Benefit | Trade-off |
|----------|---------|-----------|
| Microservices | Scalability demo | Operational complexity |
| Shared Database | Simplicity | Coupling between services |
| Sync REST | Easy debugging | Tight coupling, latency |
| JWT Auth | Stateless scaling | Token revocation complexity |
| Next.js SSR | SEO, performance | Learning curve |
| No Message Queue | Simplicity | No async processing |

### Future Evolution Path

```
Current State (v1.0)                 Future State (v2.0)
─────────────────────                ─────────────────────
Shared PostgreSQL        →           Database per service
Sync REST calls          →           Event-driven (Kafka/RabbitMQ)
No caching               →           Redis caching layer
Basic logging            →           ELK Stack centralized logging
Manual scaling           →           HPA auto-scaling
No circuit breaker       →           Resilience patterns (Polly)
```

---

## Conclusion

The architectural decisions made for this project prioritize:

1. **Learning Objectives** - Demonstrating cloud-native patterns for IT460
2. **Simplicity** - Avoiding over-engineering for a course project
3. **Best Practices** - Following industry-standard patterns where practical
4. **Extensibility** - Designing for future enhancements

Each decision balances theoretical best practices with practical implementation considerations appropriate for an academic project.

---

**Document Version:** 1.0  
**Last Updated:** 2024
