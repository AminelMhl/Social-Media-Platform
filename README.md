# Social Media Microservices Project

This is a simple social media application built as a multi-microservice project.

- Backend: NestJS (Node.js)
- Frontend: Next.js (React)
- Database: PostgreSQL
- Orchestration: Docker Compose

## Services

- `user-service` – user signup, login, profile (JWT auth, PostgreSQL)
- `post-service` – CRUD for posts (PostgreSQL, queries user-service for author info)
- `comment-service` – CRUD for comments (PostgreSQL, queries post-service and user-service)
- `message-service` – direct messages between users (PostgreSQL, queries user-service)
- `frontend` – Next.js app that talks to all backend services via REST APIs
- `db` – PostgreSQL instance shared by all services

## Prerequisites

- Docker
- Docker Compose

## Running locally with Docker Compose

1. Clone or copy this repository.
2. (Optional) Copy `.env.example` to `.env` and adjust values if needed.
3. Build and start all services:

   ```bash
   docker compose up --build
   ```

4. Open the frontend in your browser:

   - Frontend: `http://localhost:3000`

5. Backend services (if you want to inspect them directly):

   - User Service: `http://localhost:3001`
- Post Service: `http://localhost:3002`
- Comment Service: `http://localhost:3003`
  - Message Service: `http://localhost:3004`

PostgreSQL is available on `localhost:5432` with the credentials from `docker-compose.yml`.

## Environment configuration

- Database connection details and JWT configuration are set via environment variables.
- Docker Compose already passes appropriate values to each service for local development.
- Frontend communicates with backend services using the `NEXT_PUBLIC_*` environment variables to form API URLs, which are exposed to the browser.

## Basic API overview

### User Service

- `POST /auth/signup` – create account and receive JWT
- `POST /auth/login` – login with email and password, returns JWT
- `GET /users/me` – get current user profile (requires `Authorization: Bearer <token>`)
- `GET /users/:id` – get public profile of a user

### Post Service

- `POST /posts` – create a post
- `GET /posts` – list posts (includes author info from user-service)
- `GET /posts/:id` – get a single post (includes author info)
- `PUT /posts/:id` – update a post
- `DELETE /posts/:id` – delete a post

### Comment Service

- `POST /comments` – add comment to a post
- `GET /comments/post/:postId` – list comments for a post (includes author info)
- `DELETE /comments/:id` – delete a comment

### Message Service

- `POST /messages` – send a message to another user (auth required)
- `GET /messages/conversation/:userId` – get messages between the current user and another user

## Frontend pages

- `/signup` – user registration
- `/login` – user login
- `/profile` – view current user profile
- `/feed` – view posts and comments, create posts and comments
  - `/users/[id]` – view public profile of another user
  - `/messages/[id]` – view and send direct messages with another user

All frontend calls are made via REST APIs to the three backend services using the configured service URLs.
