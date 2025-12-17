# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Next AI Draw.io is a Next.js application that integrates AI capabilities with draw.io diagrams. Users can create, modify, and enhance diagrams through natural language commands using LLMs.

## Development Commands

```bash
# Development (runs on port 6002 with Turbopack)
npm run dev

# Production build
npm run build

# Production server (runs on port 6001)
npm start

# Linting
npm run lint
```

## Environment Setup

### AWS Bedrock with SSO

The app uses AWS Bedrock with the `bedrock-users` SSO profile.

**Setup:**

1. **Authenticate with AWS SSO:**
   ```bash
   aws sso login --profile bedrock-users
   ```

2. **Start the development server:**
   ```bash
   npm run dev
   ```

The app uses `fromNodeProviderChain()` which automatically discovers SSO credentials when `AWS_PROFILE` is set in `.env.local`.

**When credentials expire** (8-12 hours), just re-run `aws sso login --profile bedrock-users` and restart the dev server.

### Alternative AI Providers

The app supports 9 AI providers. Set `AI_PROVIDER` and the relevant API key in `.env.local`:
- `bedrock` (default) - AWS Bedrock
- `openai` - OpenAI
- `anthropic` - Anthropic direct
- `google` - Google Gemini
- `azure` - Azure OpenAI
- `ollama` - Local Ollama
- `openrouter` - OpenRouter
- `deepseek` - DeepSeek
- `siliconflow` - SiliconFlow

See `env.example` for all configuration options.

## Docker Development (Recommended)

Docker avoids local Node version conflicts and includes a self-hosted draw.io instance.

### Setup

1. **Create `docker-compose.override.yml`** (already exists, gitignored):
   ```yaml
   services:
     next-ai-draw-io:
       volumes:
         - ~/.aws:/home/nextjs/.aws:ro
       environment:
         - AWS_PROFILE=bedrock-users
         - AWS_REGION=us-west-2
         - AI_PROVIDER=bedrock
         - AI_MODEL=us.anthropic.claude-sonnet-4-5-20250929-v1:0
   ```

2. **Create empty `.env` file** (required by base docker-compose.yml):
   ```bash
   touch .env
   ```

3. **Authenticate and run:**
   ```bash
   aws sso login --profile bedrock-users
   docker compose up --build
   ```

### Services

| Service | Port | Description |
|---------|------|-------------|
| next-ai-draw-io | 3000 | Main app |
| drawio | 8081 | Self-hosted draw.io |

### Commands

```bash
# Start (with rebuild)
docker compose up --build

# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down

# Force rebuild (after config changes)
docker compose build --no-cache next-ai-draw-io
```

### Changing the Model

Edit `docker-compose.override.yml` and set `AI_MODEL`:
- `us.anthropic.claude-sonnet-4-5-20250929-v1:0` (Sonnet 4.5 - default)
- `us.anthropic.claude-opus-4-5-20250929-v1:0` (Opus 4.5)
- `us.anthropic.claude-sonnet-4-20250514-v1:0` (Sonnet 4)
- `us.anthropic.claude-3-5-haiku-20241022-v1:0` (Haiku 3.5 - faster/cheaper)

## Architecture

### Core Flow

1. **User Interaction**: User sends text/image input via chat interface (`components/chat-panel.tsx`)
2. **AI Processing**: Request goes to `/api/chat` route which uses AI SDK to generate responses
3. **Tool Execution**: AI calls diagram tools
4. **Diagram Rendering**: XML is loaded into `react-drawio` embed component for visualization

### Key Components

- **AI Providers** (`lib/ai-providers.ts`): Abstracted multi-provider support with `getAIModel()` function
  - Supports 9 providers: bedrock, openai, anthropic, google, azure, ollama, openrouter, deepseek, siliconflow
  - Uses `fromNodeProviderChain()` for AWS credential discovery

- **Chat API Route** (`app/api/chat/route.ts`):
  - Handles AI chat requests with provider abstraction
  - Implements three diagram tools
  - Uses tool input streaming (fine-grained streaming beta feature)

- **DiagramContext** (`contexts/diagram-context.tsx`): Global state management for diagram XML, SVG, and history

### Diagram Tools

The AI uses three tools:

1. **`display_diagram`**: Generate new diagrams
   - Pass ONLY mxCell elements (no wrapper tags like `<mxfile>`, `<root>`)
   - Root cells (id="0", id="1") are added automatically
   - IDs start from "2"

2. **`edit_diagram`**: ID-based operations on existing diagrams
   - `update`: Replace an existing cell by its id
   - `add`: Add a new cell with a new unique id
   - `delete`: Remove a cell by its id

3. **`append_diagram`**: Continue truncated output
   - Used when `display_diagram` output was truncated due to length limits

### Critical Layout Constraints

All diagrams must fit within single viewport to avoid page breaks:
- X coordinates: 0-800
- Y coordinates: 0-600
- Max container width: 700px
- Max container height: 550px

## Technology Stack

- **Framework**: Next.js 15 (App Router)
- **AI Integration**: Vercel AI SDK (`ai`, `@ai-sdk/react`)
- **Diagram Rendering**: `react-drawio` package
- **AI Providers**: 9 providers (Bedrock, OpenAI, Anthropic, Google, Azure, Ollama, OpenRouter, DeepSeek, SiliconFlow)
- **XML Processing**: `@xmldom/xmldom`, `pako` (compression), `jsdom`
- **Styling**: Tailwind CSS 4 with Radix UI components
- **Deployment**: Docker support available (Dockerfile + docker-compose.yml)

## Path Aliases

- `@/*` maps to repository root (configured in `tsconfig.json`)

## Troubleshooting

### AWS Bedrock Authentication Errors

**Error: "AWS SigV4 authentication requires AWS credentials"**
- Solution: Run `aws sso login --profile bedrock-users`, then restart the dev server.

**Error: "The security token included in the request is invalid"**
- Solution: Your SSO session has expired. Run `aws sso login --profile bedrock-users` and restart the server.

**Error: "Invocation of model ID ... with on-demand throughput isn't supported"**
- Solution: Use Bedrock inference profile IDs (e.g., `us.anthropic.claude-sonnet-4-5-20250929-v1:0`) instead of direct model IDs.

### Checking Your AWS Setup

```bash
# Verify SSO authentication
aws sts get-caller-identity --profile bedrock-users

# List available inference profiles
aws bedrock list-inference-profiles --region us-west-2 --profile bedrock-users
```
