provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

resource "kubernetes_deployment" "hello" {
  metadata {
    name      = "hello"
    namespace = "default"
    labels = {
      app = "hello"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "hello"
      }
    }
    template {
      metadata {
        labels = {
          app = "hello"
        }
      }
      spec {
        container {
          name = "hello"
          # ECR에서 빌드·푸시한 이미지를 사용
          image = var.image_uri
          port {
            container_port = 8080
          }
        }
      }
    }
  }
  depends_on = [module.eks]
}

resource "kubernetes_service" "hello" {
  metadata {
    name      = "hello"
    namespace = "default"
  }
  spec {
    selector = {
      app = "hello"
    }
    port {
      port        = 8080
      target_port = 8080
    }
    # ALB Ingress Controller는 NodePort나 ClusterIP 둘 다 지원하지만,
    # 권장되는 패턴은 NodePort (기본값)로 ELB가 워커 노드의 노드포트로 라우팅
    type = "NodePort"
  }
  depends_on = [module.eks]
}

resource "kubernetes_ingress_v1" "alb" {
  metadata {
    name      = "hello-alb"
    namespace = "default"
    annotations = {
      # 반드시 ingressClassName 과 매치되어야 합니다
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
      # (선택) 헬스체크 경로 지정
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
      # (선택) listener 포트, 기본 80
      "alb.ingress.kubernetes.io/listen-ports" = jsonencode([
        { HTTP = 80 }
      ])
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service.hello.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
  depends_on = [module.eks]
}
