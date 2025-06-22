# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the X-Terraform Agent project.

## Workflows

### 1. **CI/CD Pipeline** (`ci.yml`)
- **Triggers:** Push to `main`/`develop`, Pull Requests, Releases
- **Jobs:**
  - **Test:** Runs unit tests and coverage
  - **Build:** Creates packages for releases
  - **Release:** Creates GitHub releases with downloadable packages
  - **Docker:** Builds and pushes Docker images

### 2. **Development Pipeline** (`develop.yml`)
- **Triggers:** Push to `develop`, Pull Requests to `develop`
- **Jobs:**
  - **Test (Development):** Runs tests with linting and coverage
  - **Build Development Package:** Creates development packages

### 3. **Release** (`release.yml`)
- **Triggers:** Push of version tags (e.g., `v1.0.0`)
- **Jobs:**
  - **Create Release:** Automatically creates GitHub releases with packages

### 4. **Security** (`security.yml`)
- **Triggers:** Weekly schedule, Push to main/develop, Pull Requests
- **Jobs:**
  - **Security Scan:** Runs safety and bandit security checks
  - **Dependency Update Check:** Monitors for outdated dependencies

## Usage

### For Development
1. Create a feature branch from `develop`
2. Make your changes
3. Push to your branch
4. Create a Pull Request to `develop`
5. Workflows will automatically run tests and checks

### For Releases
1. Update version in code
2. Create and push a version tag:
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```
3. GitHub Actions will automatically:
   - Run all tests
   - Build the package
   - Create a GitHub release
   - Upload downloadable packages

### For Main Branch
- Push directly to `main` for hotfixes
- Workflows will run tests and build packages
- No automatic releases (use tags for releases)

## Secrets Required

For full functionality, add these secrets to your repository:

- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub password/token

## Free Tier Limits

GitHub Actions free tier includes:
- 2,000 minutes/month for public repositories
- 500 minutes/month for private repositories

Our workflows are optimized to stay within these limits.

## Manual Triggers

You can manually trigger workflows:
1. Go to Actions tab in your repository
2. Select the workflow
3. Click "Run workflow"
4. Choose branch and options
5. Click "Run workflow" 