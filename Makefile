IMAGE ?= k8sresourceautoresizer
VERSION ?= latest
DOCKERFILE ?= Dockerfile
DOCKER_BUILD_ARGS ?= --no-cache

.PHONY: help
##@ General
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: \033[36m\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: docker-build
##@ Docker
docker-build: ## Build Docker image locally
	@docker build $(DOCKER_BUILD_ARGS) -t $(IMAGE):$(VERSION) -f $(DOCKERFILE) .

## @ Development
.PHONY: pre-commit-run pre-commit-install pre-commit-update lint format
pre-commit-run: ## Run pre-commit hooks
	@uv run prek run --all-files

pre-commit-install: ## Install pre-commit hooks
	@uv run prek install
	@uv run prek install --hook-type commit-msg

pre-commit-update: ## Update pre-commit hooks
	@uv run prek autoupdate

lint: ## Run linters
	@uv run ruff check .

format: ## Run code formatters
	@uv run ruff format
	@uv run isort .

argo-cd-password: ## Get Argo CD initial admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argo-cd-ui: ## Access argocd ui
	@kubectl port-forward svc/argocd-server -n argocd 8088:443

.PHONY: bump-version bump-preview
##@ Release
bump-version: ## Bump project version
	@uv run cz bump

bump-preview: ## Preview next version and changelog (dry-run)
	@uv run cz bump --get-next
	@uv run cz changelog --dry-run
