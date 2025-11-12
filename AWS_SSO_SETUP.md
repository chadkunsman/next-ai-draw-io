# AWS SSO Setup Guide

This project is configured to use AWS SSO for Bedrock authentication.

## Quick Start

1. **Login to AWS SSO** (required before running the app):
   ```bash
   aws sso login --profile default
   ```

2. **Start the development server**:
   ```bash
   npm run dev
   ```

3. **Open the app**: Navigate to http://localhost:6002

## Configuration

Your `.env.local` file is configured with:
- `AWS_PROFILE=default` - Uses the default SSO profile
- `AWS_REGION=us-west-2` - Your SSO region

## Available AWS Profiles

You can change the `AWS_PROFILE` in `.env.local` to any of these:
- `default` - DeveloperAdmin (Account: 241521326540)
- `gusto-main` - DevelopersSetup (Account: 226779328744)
- `it-services-admin` - ITServicesAdmin (Account: 832806629529)
- `gusto-engineering-sandbox` - DeveloperAdmin (Account: 241521326540)

## Troubleshooting

### "Token is expired" or authentication errors
Your SSO session has expired. Re-authenticate with:
```bash
aws sso login --profile default
```

### Check your current session
```bash
aws sts get-caller-identity --profile default
```

### Verify Bedrock access
```bash
aws bedrock list-foundation-models --profile default --region us-west-2
```

## How It Works

The AWS SDK for JavaScript v3 (used by `@ai-sdk/amazon-bedrock`) automatically uses the credential chain, which includes:
1. Environment variables (`AWS_PROFILE`)
2. SSO cached credentials (`~/.aws/sso/cache/`)
3. Your AWS config file (`~/.aws/config`)

No need to set `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` when using SSO!

## Session Duration

SSO sessions typically last 8-12 hours. If you encounter authentication errors during development, simply run `aws sso login` again.
