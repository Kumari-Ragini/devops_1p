APP_IMAGE ?= devops-demo-api
AWS_ACCOUNT ?= 123456789012
AWS_REGION ?= ap-south-1
ECR_REPO ?= devops-demo-api
TAG ?= latest

.PHONY: test build run scan login-ecr push init plan apply destroy kubeconfig deploy helm-up helm-down

## ---------- Local Dev ----------
test:
	pytest -q || true

build:
	docker build -t $(APP_IMAGE):local -f Docker/Dockerfile .

run:
	docker run --rm -p 5000:5000 $(APP_IMAGE):local

scan:
	trivy image --exit-code 1 --severity HIGH,CRITICAL $(APP_IMAGE):local || true

## ---------- AWS ECR ----------
login-ecr:
	aws ecr get-login-password --region $(AWS_REGION) \
	| docker login --username AWS --password-stdin $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com

push: login-ecr
	docker tag $(APP_IMAGE):local $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO):$(TAG)
	docker push $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO):$(TAG)

## ---------- Terraform (Infra) ----------
init:
	cd terraform && terraform init

plan:
	cd terraform && terraform plan

apply:
	cd terraform && terraform apply -auto-approve

destroy:
	cd terraform && terraform destroy -auto-approve

kubeconfig:
	aws eks update-kubeconfig --name devops-demo --region $(AWS_REGION)

## ---------- Kubernetes (App Deploy) ----------
deploy: push kubeconfig
	helm upgrade --install api ./helm/app-chart \
		--namespace demo \
		--create-namespace \
		--set image.repository=$(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_REPO) \
		--set image.tag=$(TAG)

helm-up:
	helm upgrade --install api ./helm/app-chart -n demo

helm-down:
	helm uninstall api -n demo

