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

# Production server with automatic credential refresh
./start-prod.sh

# Linting
npm run lint
```

### Quick Start for Production

The `start-prod.sh` script provides a convenient wrapper that:
1. Checks if your AWS SSO session is valid
2. Automatically refreshes credentials to `.env.local`
3. Starts the production server

```bash
./start-prod.sh
```

If your session is expired, it will prompt you to run `aws sso login --profile default` first.

## Environment Setup

### AWS Bedrock with SSO (Recommended)

The app uses AWS Bedrock's Claude Sonnet 4.5 by default via inference profile `us.anthropic.claude-sonnet-4-5-20250929-v1:0` (configured in `app/api/chat/route.ts:142`).

**Setup Process (Development):**

1. **Authenticate with AWS SSO:**
   ```bash
   aws sso login --profile default
   ```

2. **Refresh credentials for Next.js:**
   ```bash
   ./refresh-aws-creds.sh
   ```
   This script exports your SSO credentials to `.env.local` as:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`
   - `AWS_REGION`

3. **Start the development server:**
   ```bash
   npm run dev
   ```

**Setup Process (Production):**

For production, use the convenience script that handles everything:
```bash
./start-prod.sh
```

Or manually:
```bash
aws sso login --profile default
./refresh-aws-creds.sh
npm start
```

**Important Notes:**
- SSO credentials expire after 8-12 hours. When they expire, re-run `./refresh-aws-creds.sh` and restart the dev server.
- The app uses Bedrock inference profiles (prefixed with `us.` or `global.`) for on-demand access, not direct model IDs.
- Next.js server environment doesn't support `fromSSO()` credential provider, so we use exported environment variables instead.

### Alternative AI Providers

If not using AWS Bedrock, configure one of these providers in `.env.local`:
- `GOOGLE_GENERATIVE_AI_API_KEY` (Google Gemini)
- `OPENAI_API_KEY` (OpenAI)
- `OPENROUTER_API_KEY` (OpenRouter)

Update the model in `app/api/chat/route.ts` to use your preferred provider.

## Architecture

### Core Flow

1. **User Interaction**: User sends text/image input via chat interface (`components/chat-panel.tsx`)
2. **AI Processing**: Request goes to `/api/chat` route which uses AI SDK to generate responses
3. **Tool Execution**: AI can call two tools:
   - `display_diagram`: Creates/replaces entire diagram (for new diagrams or major changes)
   - `edit_diagram`: Makes surgical edits to existing diagram XML (for targeted modifications)
4. **Diagram Rendering**: XML is loaded into `react-drawio` embed component for visualization

### Key Components

- **DiagramContext** (`contexts/diagram-context.tsx`): Global state management for diagram XML, SVG, and history
  - Manages diagram loading, exporting, and history tracking
  - Provides refs for draw.io embed instance and export resolver

- **Chat API Route** (`app/api/chat/route.ts`):
  - Handles AI chat requests with multi-provider support
  - Includes detailed system prompt for diagram generation
  - Implements two tools: `display_diagram` and `edit_diagram`
  - Uses tool input streaming (fine-grained streaming beta feature)

- **ChatPanel** (`components/chat-panel.tsx`):
  - Main chat interface with file upload support
  - Handles tool execution callbacks
  - Fetches current diagram XML before each message
  - Formats XML for consistency before sending to AI

### XML Processing Utilities (`lib/utils.ts`)

Critical utilities for diagram manipulation:

- **`formatXML(xml)`**: Formats XML with proper indentation and line breaks
- **`replaceNodes(currentXML, nodes)`**: Replaces entire `<root>` node structure in diagram
- **`replaceXMLParts(xmlContent, searchReplacePairs)`**: Makes surgical edits by finding and replacing exact XML fragments
  - Uses three-tier matching strategy: exact line match → trimmed line match → substring match
  - Throws error if pattern not found (important for error handling in edit_diagram)
- **`extractDiagramXML(xml_svg_string)`**: Extracts compressed XML from draw.io's SVG export format (base64 + pako compression)

### Tool Strategy

The AI uses two distinct approaches:
- **display_diagram**: Pass complete `<root>` node with all `<mxCell>` elements (regenerate entire diagram)
- **edit_diagram**: Pass minimal search/replace pairs with only the lines being changed plus 1-2 context lines
  - If edit fails, AI should fall back to `display_diagram` rather than retry with different patterns

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
- **AI Providers**: AWS Bedrock, Google Gemini, OpenAI, OpenRouter
- **XML Processing**: `@xmldom/xmldom`, `pako` (compression), `jsdom`
- **Styling**: Tailwind CSS 4 with Radix UI components

## Path Aliases

- `@/*` maps to repository root (configured in `tsconfig.json`)

## Troubleshooting

### AWS Bedrock Authentication Errors

**Error: "AWS SigV4 authentication requires AWS credentials"**
- Solution: Run `./refresh-aws-creds.sh` to export your SSO credentials to `.env.local`, then restart the dev server.

**Error: "The security token included in the request is invalid"**
- Solution: Your SSO session has expired. Run `aws sso login --profile default`, then `./refresh-aws-creds.sh`, and restart the server.

**Error: "Invocation of model ID ... with on-demand throughput isn't supported"**
- Solution: Use Bedrock inference profile IDs (e.g., `us.anthropic.claude-sonnet-4-5-20250929-v1:0`) instead of direct model IDs.
- List available profiles: `aws bedrock list-inference-profiles --region us-west-2`

### Checking Your AWS Setup

```bash
# Verify SSO authentication
aws sts get-caller-identity

# Check credential expiration
cat .env.local | grep "Credential expiration"

# List available Claude models
aws bedrock list-foundation-models --region us-west-2 --by-provider anthropic

# List available inference profiles
aws bedrock list-inference-profiles --region us-west-2
```
