# Electro App - Cloud/DevOps Take-Home Project

This project is a complete three-tier application deployment on AWS, built from scratch with Infrastructure as Code, containerization, CI/CD, and basic security/monitoring controls.

## 1. Scenario Mapping

Application tiers:
- Frontend: Static website hosted in S3 Website Hosting.
- Backend API: FastAPI container running on ECS Fargate behind an Application Load Balancer.
- Database: Managed PostgreSQL on Amazon RDS.

Automation:
- Infrastructure: Terraform in separate files under `infra/terraform`.
- App container: Docker multi-stage build with non-root runtime user.
- Delivery: GitHub Actions pipeline for Build -> Test -> Docker Build/Push -> Terraform Deploy.

## 2. Architecture

See diagram: `docs/architecture.md`

High-level flow:
- User opens frontend static site in S3.
- Frontend calls backend API via ALB endpoint.
- Backend reads/writes from RDS.
- ECS/ALB logs and metrics flow to CloudWatch.
- CloudWatch alarm notifies SNS email.

## 3. Repository Structure

- `src/backend`: API code, tests, Dockerfile.
- `frontend`: Static frontend files.
- `infra/terraform`: AWS infrastructure IaC split into multiple files.
- `.github/workflows/ci-cd.yml`: CI/CD pipeline.
- `scripts/update-frontend-config.ps1`: Updates frontend API URL from Terraform outputs.
- `docs/architecture.md`: Diagram.

## 4. Step-by-Step Build and Deploy

### Step 1: Prerequisites
Install:
- AWS CLI v2
- Docker
- Terraform >= 1.6
- Python 3.12+
- Git

Configure AWS credentials locally:
```powershell
aws configure
```

### Step 2: Local Backend Validation
From project root:
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r src/backend/requirements-dev.txt
pytest src/backend/tests -q
```

Expected result:
- Test passes for `/health` endpoint.

### Step 3: Local Container Validation
```powershell
docker compose up --build
```

Verify:
- Backend health: `http://localhost:8000/health`
- Backend hello: `http://localhost:8000/hello`
- DB check: `http://localhost:8000/db-check`

### Step 4: Terraform Configuration
Copy sample variables and set secure values:
```powershell
Copy-Item infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
```

Set DB password using environment variable (recommended):
```powershell
$env:TF_VAR_db_password = "replace-with-strong-password"
```

### Step 5: Provision Cloud Infrastructure
```powershell
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform apply -auto-approve
```

Get outputs:
```powershell
terraform -chdir=infra/terraform output
```

### Step 6: Update Frontend API URL
```powershell
./scripts/update-frontend-config.ps1
```

Then re-apply so Terraform uploads updated frontend config to S3:
```powershell
terraform -chdir=infra/terraform apply -auto-approve
```

### Step 7: Push to GitHub and Enable CI/CD
Push this repository to GitHub and create secrets:
- `AWS_REGION`
- `AWS_ROLE_TO_ASSUME` (OIDC role ARN)
- `DB_PASSWORD`
- `ALERT_EMAIL`

Pipeline file:
- `.github/workflows/ci-cd.yml`

Pipeline on push to `main`:
1. Install dependencies
2. Run tests
3. Build Docker image
4. Push image to ECR
5. Run Terraform apply with the image tag

## 5. Security Choices

Implemented controls:
- Least privilege direction:
  - Separate ECS task execution role and task role.
  - Security groups restrict traffic paths:
    - ALB accepts only HTTP/80 from internet.
    - ECS accepts only app port from ALB SG.
    - RDS accepts only 5432 from ECS SG.
- Secrets handling:
  - No DB password hard-coded in code.
  - `db_password` is sensitive Terraform variable.
  - CI injects secrets via GitHub Secrets.
- Encryption:
  - RDS storage encryption enabled.
  - S3 server-side encryption enabled.
  - ECR image encryption enabled.

## 6. Monitoring and Alerting

Implemented:
- ECS logs in CloudWatch log group (`/ecs/<project>-<env>-backend`).
- CloudWatch alarm on `HTTPCode_ELB_5XX_Count`.
- Alarm action to SNS topic with optional email subscription.

Validation:
- Confirm alarm resource in CloudWatch.
- Confirm SNS email subscription (after email confirmation).

## 7. Naming and Tagging Convention

Naming pattern:
- `<project_name>-<environment>-<resource>`

Standard tags on resources:
- `Project`
- `Environment`
- `ManagedBy=terraform`

## 8. Evidence Collection (Screenshots + Video)

Take these screenshots:
1. Terraform apply success output.
2. AWS VPC subnets view (public/private).
3. ECS service running task (healthy).
4. RDS instance available.
5. S3 frontend page loaded in browser.
6. Backend `/hello` API response in browser/Postman.
7. GitHub Actions run showing all stages succeeded.
8. CloudWatch alarm and SNS topic/subscription.

Suggested short demo video (3-5 min):
1. Show repository structure and Terraform files.
2. Run `pytest` and show passing test.
3. Show Docker build/run locally.
4. Show Terraform apply and outputs.
5. Open frontend URL and invoke backend call.
6. Show GitHub Actions pipeline run.
7. Show CloudWatch logs/metrics/alarm.

## 9. Trade-offs (Time-boxed Assessment)

Trade-offs made:
- S3 static website endpoint is used for simplicity instead of CloudFront + OAC.
- Single RDS instance (no Multi-AZ) to reduce cost and complexity.
- Basic test coverage to satisfy CI test requirement.
- ECS app uses environment variables for DB credentials for simplicity.

## 10. How This Would Change for Production (<= half page)

For production, I would improve scale, cost control, and availability in these ways:
- Scale and HA:
  - Place frontend behind CloudFront with origin access control and WAF.
  - Use ECS autoscaling based on CPU/latency and at least two tasks across AZs.
  - Move RDS to Multi-AZ and add read replicas if read-heavy.
- Security:
  - Store DB credentials in AWS Secrets Manager and inject at runtime.
  - Enforce TLS end-to-end and use ACM certs on ALB/CloudFront.
  - Tighten IAM policies further to exact resource ARNs/actions.
- Cost and operations:
  - Add lifecycle policies for ECR and log retention tuning.
  - Add budget alarms and dashboards.
  - Split Terraform into reusable modules and separate state per environment.
- Delivery quality:
  - Add separate `dev/stage/prod` pipeline stages with approvals for prod.
  - Add smoke/integration tests and rollback strategy.

## 11. Cleanup

Destroy cloud resources when done
```powershell
terraform -chdir=infra/terraform destroy -auto-approve
```
