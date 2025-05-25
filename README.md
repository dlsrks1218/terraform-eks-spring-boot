# Terraform을 통한 EKS 구축 및 ALB를 통한 Spring Boot 서비스 라우팅

## 사전 요구 사항

    -  Terraform 클라우드 등의 Terraform backend 설정이 필요하며 backend.tf를 환경에 맞게 수정해야합니다. 추가로 Terraform 클라우드의 경우 Workspace 혹은 Organization Variable Sets에 EKS 및 VPC 구성에 필요한 권한을 가진 IAM 사용자의 AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY를 추가해야 합니다.
    -  vars.tf에 account id 12자리와 클러스터 구성에 필요한 변수들을 수정해야합니다.
    - 생성된 EKS 클러스터에 접근할 IAM 사용자 혹은 역할을 생성 후 main.tf의 local 내부에 rbac_xx_user에 해당 arn을 추가해야 생성자 이외의 사용자 혹은 역할에서 접근이 가능합니다.
    - AWS 계정에 ECR이 존재해야하며, 아래 프로젝트에서 도커 이미지를 빌드하여 ECR에  푸시한 후 vars.tf의 image_uri에 uri를 추가해야 합니다.
        - https://github.com/dlsrks1218/terraform-eks-spring-boot
            * 이미지 빌드 방법은 상기 리포지토리의 README.md에 작성되어있으니 참고 부탁드립니다.

## Terraform을 통한 리소스 생성

    - Terraform apply를 위한 workspace 구성 및 version controll(ex - GitHub App)가 구성 되어있다면, Terraform 리소스를 위한 GitHub 리포지토리에 푸시되면 Terraform 클라우드에서 plan 확인 후 apply 적용

## 생성되는 순서

    1. vpc
        * cidr = "10.21.0.0/16"
            *  az 별 NAT GW 1개씩 구성
        * public_subnets  = ["10.21.0.0/24", "10.21.1.0/24"]
        * private_subnets = ["10.21.32.0/24", "10.21.33.0/24"]
        * az = ["ap-northeast-2a", "ap-northeast-2c"]
    2. EKS
        * 클러스터 API 액세스 - Terraform 클라우드 단에서 Helm을 통한 배포를 위해 전체 대역으로 개방, 추후 cidr을 제한 필요
        * 접근 제어 - Access Entries
            * local에 선언한 admin, developer 사용자에게 각각 관리자, 뷰어 권한을 부여하여 접근하도록 설정
        * 관리형 노드그룹을 생성하고 라벨링을 통해 프라이빗 서브넷임을 명시하고 애플리케이션 단에서 affinity를 통해 프라이빗 서브넷에 전개된 노드에 위치
            * nodeAffinity의 requiredDuringSchedulingIgnoredDuringExecution를 구성하여 프라이빗 서브넷 라벨링이 된 노드에만 위치하도록 구성
        * Helm으로 ALB controller를 설치
        * Deployment, Service, Ingress를 통해 ALB 및 타겟 그룹을 생성하여 프라이빗 노드에 배포된 애플리케이션을 외부로부터 트래픽을 받을 수 있도록 구성
    

## 결과 확인

    1. Terraform apply 이후 ALB 프로비저닝 시간이 조금 걸리므로 생성 결과 확인 필요
    2. Terraform Output의 **alb_dns_name에 대해 curl등을 통해 http://<ALB_DNS_NAME>/ 경로 호출 시 Hello Docker World 출력되면 성공**