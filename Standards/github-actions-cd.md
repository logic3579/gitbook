---
description: GitHub Actions CD workflow standard for ArgoCD GitOps deployment, triggered by repository-dispatch from CI pipelines
tags:
  - standards
  - ci-cd
---

# GitHub Actions CD

GitHub Actions CD workflow standard for ArgoCD GitOps deployment. This workflow runs in a dedicated DevOps repository, receiving `repository_dispatch` events from application CI pipelines.

Pipeline: receive dispatch event → validate payload → update Helm values file with new image tag → commit and push → ArgoCD syncs to cluster.

## Workflow Example

```yaml
# CD Workflow - Deploy Applications via ArgoCD GitOps
# Triggered by repository_dispatch from application CI repositories.
#
# Flow:
#   test → update helm-charts/charts/<app>/values-test.yml → ArgoCD auto-sync
#   prod → update helm-charts/charts/<app>/values-prod.yml → ArgoCD manual sync required

name: CD - Deploy Application

on:
  repository_dispatch:
    types: [deploy-app]

env:
  APP_NAME: ${{ github.event.client_payload.app }}
  IMAGE_TAG: ${{ github.event.client_payload.tag }}
  VERSION: ${{ github.event.client_payload.version }}
  ENVIRONMENT: ${{ github.event.client_payload.environment }}
  TRIGGERED_BY: ${{ github.event.client_payload.triggered_by }}
  COMMIT_MESSAGE: ${{ github.event.client_payload.commit_message }}
  SOURCE_REPO: ${{ github.event.client_payload.source_repo }}

permissions:
  contents: write

concurrency:
  group: cd-${{ github.event.client_payload.app }}-${{ github.event.client_payload.environment }}
  cancel-in-progress: false

jobs:
  # ============================================
  # Validate Incoming Payload
  # ============================================
  validate:
    runs-on: ubuntu-latest
    outputs:
      valid: ${{ steps.validate.outputs.valid }}
    steps:
      - name: Validate payload
        id: validate
        run: |
          echo "Validating deployment request..."
          echo "App: $APP_NAME"
          echo "Tag: $IMAGE_TAG"
          echo "Environment: $ENVIRONMENT"
          echo "Triggered by: $TRIGGERED_BY"

          if [[ -z "$APP_NAME" || -z "$IMAGE_TAG" || -z "$ENVIRONMENT" ]]; then
            echo "::error::Missing required payload fields"
            echo "valid=false" >> $GITHUB_OUTPUT
            exit 1
          fi

          if [[ "$ENVIRONMENT" != "test" && "$ENVIRONMENT" != "prod" ]]; then
            echo "::error::Invalid environment: $ENVIRONMENT (must be 'test' or 'prod')"
            echo "valid=false" >> $GITHUB_OUTPUT
            exit 1
          fi

          echo "valid=true" >> $GITHUB_OUTPUT
          echo "Payload validation successful"

  # ============================================
  # Deploy to Test Environment
  # ============================================
  # ArgoCD auto-sync is enabled for test — commit triggers immediate rollout.
  deploy-test:
    needs: validate
    if: >-
      needs.validate.outputs.valid == 'true' &&
      github.event.client_payload.environment == 'test'
    runs-on: ubuntu-latest
    outputs:
      deployed: ${{ steps.commit.outputs.deployed }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          fetch-depth: 0

      - name: Setup yq
        uses: mikefarah/yq@v4

      - name: Update values file
        id: update
        run: |
          VALUES_FILE="helm-charts/charts/${APP_NAME}/values-test.yml"

          if [[ ! -f "$VALUES_FILE" ]]; then
            echo "::error::Values file not found: $VALUES_FILE"
            exit 1
          fi

          echo "Updating $VALUES_FILE with tag: $IMAGE_TAG"

          # Get current tag for comparison
          CURRENT_TAG=$(yq '.image.tag' "$VALUES_FILE")
          echo "Current tag: $CURRENT_TAG"

          if [[ "$CURRENT_TAG" == "$IMAGE_TAG" ]]; then
            echo "Tag unchanged, skipping update"
            echo "changed=false" >> $GITHUB_OUTPUT
            exit 0
          fi

          # Update the image tag
          yq -i '.image.tag = strenv(IMAGE_TAG)' "$VALUES_FILE"

          echo "changed=true" >> $GITHUB_OUTPUT
          echo "Updated tag to: $IMAGE_TAG"

      - name: Commit and push
        id: commit
        if: steps.update.outputs.changed == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          git add helm-charts/charts/${APP_NAME}/values-test.yml

          COMMIT_MSG="deploy(test): ${APP_NAME} → ${IMAGE_TAG}"
          if [[ -n "$COMMIT_MESSAGE" ]]; then
            COMMIT_MSG="${COMMIT_MSG}

          Source: ${COMMIT_MESSAGE}
          Triggered by: ${TRIGGERED_BY}"
          fi

          git commit -m "$COMMIT_MSG"
          git pull --rebase origin main
          git push

          echo "deployed=true" >> $GITHUB_OUTPUT
          echo "Changes committed and pushed"

      - name: No changes to deploy
        if: steps.update.outputs.changed != 'true'
        run: |
          echo "deployed=false" >> $GITHUB_OUTPUT
          echo "No changes detected, skipping deployment"

  # ============================================
  # Deploy to Prod Environment
  # ============================================
  # ArgoCD manual sync is required for prod — commit updates the desired
  # state, but an operator must approve the sync in the ArgoCD dashboard.
  deploy-prod:
    needs: validate
    if: >-
      needs.validate.outputs.valid == 'true' &&
      github.event.client_payload.environment == 'prod'
    runs-on: ubuntu-latest
    outputs:
      deployed: ${{ steps.commit.outputs.deployed }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          fetch-depth: 0

      - name: Setup yq
        uses: mikefarah/yq@v4

      - name: Update values file
        id: update
        run: |
          VALUES_FILE="helm-charts/charts/${APP_NAME}/values-prod.yml"

          if [[ ! -f "$VALUES_FILE" ]]; then
            echo "::error::Values file not found: $VALUES_FILE"
            exit 1
          fi

          echo "Updating $VALUES_FILE with tag: $IMAGE_TAG"

          # Get current tag for comparison
          CURRENT_TAG=$(yq '.image.tag' "$VALUES_FILE")
          echo "Current tag: $CURRENT_TAG"

          if [[ "$CURRENT_TAG" == "$IMAGE_TAG" ]]; then
            echo "Tag unchanged, skipping update"
            echo "changed=false" >> $GITHUB_OUTPUT
            exit 0
          fi

          # Update the image tag
          yq -i '.image.tag = strenv(IMAGE_TAG)' "$VALUES_FILE"

          echo "changed=true" >> $GITHUB_OUTPUT
          echo "Updated tag to: $IMAGE_TAG"

      - name: Commit and push
        id: commit
        if: steps.update.outputs.changed == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          git add helm-charts/charts/${APP_NAME}/values-prod.yml

          COMMIT_MSG="deploy(prod): ${APP_NAME} → ${IMAGE_TAG}"
          if [[ -n "$COMMIT_MESSAGE" ]]; then
            COMMIT_MSG="${COMMIT_MSG}

          Source: ${COMMIT_MESSAGE}
          Triggered by: ${TRIGGERED_BY}"
          fi

          git commit -m "$COMMIT_MSG"
          git pull --rebase origin main
          git push

          echo "deployed=true" >> $GITHUB_OUTPUT
          echo "Changes committed and pushed"

      - name: No changes to deploy
        if: steps.update.outputs.changed != 'true'
        run: |
          echo "deployed=false" >> $GITHUB_OUTPUT
          echo "No changes detected, skipping deployment"

  # ============================================
  # Notification
  # ============================================
  notify:
    needs: [validate, deploy-test, deploy-prod]
    if: always() && needs.validate.outputs.valid == 'true'
    runs-on: ubuntu-latest
    steps:
      - name: Determine status
        id: status
        run: |
          if [[ "$ENVIRONMENT" == "test" ]]; then
            DEPLOYED="${{ needs.deploy-test.outputs.deployed }}"
          else
            DEPLOYED="${{ needs.deploy-prod.outputs.deployed }}"
          fi

          if [[ "$DEPLOYED" == "true" ]]; then
            echo "status=success" >> $GITHUB_OUTPUT
          else
            echo "status=skipped" >> $GITHUB_OUTPUT
          fi

      - name: Send Slack notification
        if: steps.status.outputs.status == 'success'
        uses: slackapi/slack-github-action@v2.0.0
        with:
          webhook: ${{ secrets.SLACK_WEBHOOK_URL }}
          webhook-type: incoming-webhook
          payload: |
            {
              "blocks": [
                {
                  "type": "header",
                  "text": {
                    "type": "plain_text",
                    "text": "CD Triggered - ${{ env.APP_NAME }} (${{ env.ENVIRONMENT }})",
                    "emoji": true
                  }
                },
                {
                  "type": "section",
                  "fields": [
                    { "type": "mrkdwn", "text": "*Application:*\n${{ env.APP_NAME }}" },
                    { "type": "mrkdwn", "text": "*Environment:*\n${{ env.ENVIRONMENT }}" },
                    { "type": "mrkdwn", "text": "*Image Tag:*\n`${{ env.IMAGE_TAG }}`" },
                    { "type": "mrkdwn", "text": "*Triggered by:*\n${{ env.TRIGGERED_BY }}" }
                  ]
                },
                {
                  "type": "section",
                  "text": { "type": "mrkdwn", "text": "Helm values updated. Waiting for ArgoCD sync." }
                },
                {
                  "type": "actions",
                  "elements": [
                    {
                      "type": "button",
                      "text": { "type": "plain_text", "text": "View Workflow" },
                      "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
                    }
                  ]
                }
              ]
            }
        continue-on-error: true

      - name: Summary
        run: |
          echo "## CD Pipeline Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Field | Value |" >> $GITHUB_STEP_SUMMARY
          echo "|-------|-------|" >> $GITHUB_STEP_SUMMARY
          echo "| Application | \`$APP_NAME\` |" >> $GITHUB_STEP_SUMMARY
          echo "| Environment | $ENVIRONMENT |" >> $GITHUB_STEP_SUMMARY
          echo "| Image Tag | \`$IMAGE_TAG\` |" >> $GITHUB_STEP_SUMMARY
          echo "| Status | ${{ steps.status.outputs.status }} |" >> $GITHUB_STEP_SUMMARY
          echo "| Triggered By | $TRIGGERED_BY |" >> $GITHUB_STEP_SUMMARY
```

## Workflow Design

### Trigger Mechanism

This workflow is triggered exclusively by `repository_dispatch` events from application CI pipelines. The CI workflow sends a `deploy-app` event via `peter-evans/repository-dispatch` with a JSON payload containing the application name, image tag, target environment, and metadata.

### Payload Contract

| Field | Required | Description |
|-------|----------|-------------|
| `app` | Yes | Application name (matches Helm chart directory name) |
| `tag` | Yes | Docker image tag to deploy |
| `version` | No | Git ref name (branch or tag) |
| `environment` | Yes | Target environment (`test` or `prod`) |
| `triggered_by` | No | GitHub actor who triggered the CI pipeline |
| `commit_message` | No | Source commit message for traceability |
| `source_repo` | No | Source repository (`owner/repo` format) |

### Helm Values Structure

Each application maintains per-environment values files under the `helm-charts/` directory:

```text
helm-charts/
└── charts/
    └── app-service/
        ├── Chart.yaml
        ├── values.yaml          # Base values (shared across envs)
        ├── values-test.yml      # Test environment overrides
        ├── values-prod.yml      # Prod environment overrides
        └── templates/
            ├── deployment.yaml
            └── service.yaml
```

The CD workflow updates `.image.tag` in the environment-specific values file using `yq`:

```yaml
# values-test.yml
image:
  tag: "dev-a1b2c3d"    # ← Updated by CD workflow
```

### ArgoCD Sync Strategy

| Environment | Sync Policy | Behavior |
|-------------|-------------|----------|
| test | Auto-sync enabled | ArgoCD detects the commit and rolls out immediately |
| prod | Manual sync required | Commit updates desired state; operator approves sync in ArgoCD dashboard |

### Concurrency Control

Each application-environment pair has its own concurrency group to prevent parallel deployments to the same target, while allowing different apps or environments to deploy simultaneously:

```yaml
concurrency:
  group: cd-${{ github.event.client_payload.app }}-${{ github.event.client_payload.environment }}
  cancel-in-progress: false    # Never cancel an in-progress deployment
```

### Idempotency

The workflow compares the current image tag with the incoming tag before committing. If the tag is unchanged, the job exits early without creating an empty commit, avoiding unnecessary ArgoCD sync cycles.

### CI/CD Pipeline Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│ Application Repo (CI)                                           │
│                                                                 │
│  push / release                                                 │
│    → build Docker image                                         │
│    → push to container registry (GHCR)                          │
│    → repository-dispatch: deploy-app                            │
└──────────────────────────┬──────────────────────────────────────┘
                           │ event
┌──────────────────────────▼──────────────────────────────────────┐
│ DevOps Repo (CD)                                                │
│                                                                 │
│  repository_dispatch                                            │
│    → validate payload                                           │
│    → update helm-charts/charts/<app>/values-<env>.yml           │
│    → commit & push                                              │
│    → notify via Slack                                           │
└──────────────────────────┬──────────────────────────────────────┘
                           │ git commit detected
┌──────────────────────────▼──────────────────────────────────────┐
│ ArgoCD                                                          │
│                                                                 │
│  test: auto-sync → immediate rollout                            │
│  prod: manual sync required → operator approves in dashboard    │
└─────────────────────────────────────────────────────────────────┘
```

> Reference:
>
> 1. [GitHub Actions - repository_dispatch](https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows#repository_dispatch)
> 2. [mikefarah/yq](https://github.com/mikefarah/yq)
> 3. [slackapi/slack-github-action](https://github.com/slackapi/slack-github-action)
> 4. [Argo CD - Sync Policies](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
> 5. [peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)
