# API Reference

## Social Media Microservices Platform

Quick reference for all REST API endpoints.

---

## Base URLs

| Environment | Service | URL |
|-------------|---------|-----|
| Local | User Service | `http://localhost:3001` |
| Local | Post Service | `http://localhost:3002` |
| Local | Comment Service | `http://localhost:3003` |
| Local | Message Service | `http://localhost:3004` |
| Local | Frontend | `http://localhost:3000` |
| OpenShift | All Backend | Internal: `http://<service-name>:<port>` |
| OpenShift | Frontend | Via Route: `https://<route-url>` |

---

## Authentication

All protected endpoints require a Bearer token in the Authorization header:

```http
Authorization: Bearer <jwt-token>
```

### Getting a Token

**Login:**
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "displayName": "User Name",
    "bio": "User bio",
    "profileImageUrl": "https://..."
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## User Service (Port 3001)

### Auth Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/signup` | ❌ | Register new user |
| POST | `/auth/login` | ❌ | Login user |

### Profile Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/profile` | ✅ | Get current user profile |
| PUT | `/profile` | ✅ | Update current user profile |
| GET | `/users/:id` | ❌ | Get public user profile |

---

### POST /auth/signup

Register a new user.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "displayName": "John Doe"
}
```

**Response (201):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "displayName": "John Doe",
    "bio": null,
    "profileImageUrl": null
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Errors:**
- `400 Bad Request` - Email already exists or validation failed

---

### POST /auth/login

Authenticate user and get token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "displayName": "John Doe",
    "bio": "Hello world!",
    "profileImageUrl": "https://example.com/avatar.jpg"
  },
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Errors:**
- `400 Bad Request` - Invalid credentials

---

### GET /profile

Get current authenticated user's profile.

**Headers:**
```http
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "displayName": "John Doe",
  "bio": "Hello world!",
  "profileImageUrl": "https://example.com/avatar.jpg"
}
```

---

### PUT /profile

Update current user's profile.

**Headers:**
```http
Authorization: Bearer <token>
```

**Request:**
```json
{
  "displayName": "John Updated",
  "bio": "New bio text",
  "profileImageUrl": "https://example.com/new-avatar.jpg"
}
```

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "displayName": "John Updated",
  "bio": "New bio text",
  "profileImageUrl": "https://example.com/new-avatar.jpg"
}
```

---

### GET /users/:id

Get public profile of any user.

**Response (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "displayName": "John Doe",
  "bio": "Hello world!",
  "profileImageUrl": "https://example.com/avatar.jpg"
}
```

**Errors:**
- `404 Not Found` - User not found

---

## Post Service (Port 3002)

### Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/posts` | ❌ | List all posts |
| POST | `/posts` | ✅ | Create new post |
| GET | `/posts/:id` | ❌ | Get single post |
| PUT | `/posts/:id` | ✅ | Update post (owner only) |
| DELETE | `/posts/:id` | ✅ | Delete post (owner only) |
| POST | `/posts/:id/like` | ✅ | Upvote post |
| POST | `/posts/:id/dislike` | ✅ | Downvote post |
| DELETE | `/posts/:id/reaction` | ✅ | Remove vote |

---

### GET /posts

Get all posts with author info and reaction counts.

**Response (200):**
```json
[
  {
    "id": "post-uuid-1",
    "title": "First Post",
    "content": "This is my first post!",
    "authorId": "user-uuid",
    "author": {
      "id": "user-uuid",
      "displayName": "John Doe",
      "profileImageUrl": "https://..."
    },
    "likes": 10,
    "dislikes": 2,
    "score": 8,
    "userReaction": null,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
]
```

---

### POST /posts

Create a new post.

**Headers:**
```http
Authorization: Bearer <token>
```

**Request:**
```json
{
  "title": "My New Post",
  "content": "This is the content of my post."
}
```

**Response (201):**
```json
{
  "id": "new-post-uuid",
  "title": "My New Post",
  "content": "This is the content of my post.",
  "authorId": "user-uuid",
  "likes": 0,
  "dislikes": 0,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

---

### POST /posts/:id/like

Upvote a post (toggles if already liked).

**Headers:**
```http
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true
}
```

---

### POST /posts/:id/dislike

Downvote a post (toggles if already disliked).

**Headers:**
```http
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true
}
```

---

### DELETE /posts/:id/reaction

Remove current user's vote from a post.

**Headers:**
```http
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true
}
```

---

## Comment Service (Port 3003)

### Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/comments` | ✅ | Create comment |
| GET | `/comments/post/:postId` | ❌ | Get comments for post |
| POST | `/comments/:id/like` | ✅ | Upvote comment |
| POST | `/comments/:id/dislike` | ✅ | Downvote comment |
| DELETE | `/comments/:id/reaction` | ✅ | Remove vote |
| DELETE | `/comments/:id` | ✅ | Delete comment (owner) |

---

### POST /comments

Create a new comment on a post.

**Headers:**
```http
Authorization: Bearer <token>
```

**Request:**
```json
{
  "postId": "post-uuid",
  "content": "This is my comment!"
}
```

**Response (201):**
```json
{
  "id": "comment-uuid",
  "postId": "post-uuid",
  "authorId": "user-uuid",
  "content": "This is my comment!",
  "likes": 0,
  "dislikes": 0,
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

---

### GET /comments/post/:postId

Get all comments for a specific post.

**Response (200):**
```json
[
  {
    "id": "comment-uuid",
    "postId": "post-uuid",
    "authorId": "user-uuid",
    "author": {
      "id": "user-uuid",
      "displayName": "John Doe",
      "profileImageUrl": "https://..."
    },
    "content": "Great post!",
    "likes": 5,
    "dislikes": 0,
    "score": 5,
    "userReaction": "like",
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
]
```

---

## Message Service (Port 3004)

### Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/messages` | ✅ | Send message |
| GET | `/messages/conversation/:userId` | ✅ | Get conversation |

---

### POST /messages

Send a direct message to another user.

**Headers:**
```http
Authorization: Bearer <token>
```

**Request:**
```json
{
  "receiverId": "recipient-user-uuid",
  "content": "Hey, how are you?"
}
```

**Response (201):**
```json
{
  "id": "message-uuid",
  "senderId": "sender-user-uuid",
  "receiverId": "recipient-user-uuid",
  "content": "Hey, how are you?",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

---

### GET /messages/conversation/:userId

Get all messages in a conversation with a specific user.

**Headers:**
```http
Authorization: Bearer <token>
```

**Response (200):**
```json
[
  {
    "id": "message-uuid-1",
    "senderId": "user-uuid-1",
    "receiverId": "user-uuid-2",
    "content": "Hey!",
    "createdAt": "2024-01-01T00:00:00.000Z"
  },
  {
    "id": "message-uuid-2",
    "senderId": "user-uuid-2",
    "receiverId": "user-uuid-1",
    "content": "Hi there!",
    "createdAt": "2024-01-01T00:01:00.000Z"
  }
]
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "statusCode": 400,
  "message": "Error description",
  "error": "Bad Request"
}
```

### Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (not owner) |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## Testing with cURL

### Register User
```bash
curl -X POST http://localhost:3001/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","displayName":"Test User"}'
```

### Login
```bash
curl -X POST http://localhost:3001/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### Create Post (with token)
```bash
curl -X POST http://localhost:3002/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title":"Test Post","content":"Hello World!"}'
```

### Get All Posts
```bash
curl http://localhost:3002/posts
```

### Add Comment
```bash
curl -X POST http://localhost:3003/comments \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"postId":"POST_ID_HERE","content":"Nice post!"}'
```

### Send Message
```bash
curl -X POST http://localhost:3004/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"receiverId":"RECIPIENT_ID_HERE","content":"Hello!"}'
```

---

**Document Version:** 1.0
