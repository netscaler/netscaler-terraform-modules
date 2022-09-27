########################################################################################
#
#  Copyright (c) 2019 Citrix Systems, Inc.
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#      * Neither the name of the Citrix Systems, Inc. nor the
#        names of its contributors may be used to endorse or promote products
#        derived from this software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL Citrix Systems, Inc. BE LIABLE FOR ANY
#  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
########################################################################################

resource "kubernetes_deployment" "apache" {
  metadata {
    name = "apache"
    labels = {
      app = "apache"
    }
  }

  spec {
    replicas = 4

    selector {
      match_labels = {
        app = "apache"
      }
    }

    template {
      metadata {
        labels = {
          app = "apache"
        }
      }

      spec {
        container {
          image = "httpd:latest"
          name  = "apache"

          resources {
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "apache_service" {
  metadata {
    name = "apache-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment.apache.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress" "apache_ingress" {
  metadata {
    name = "apache-ingress"
    annotations = {
      "ingress.citrix.com/frontend-ip"         = var.frontend_ip
      //"ingress.citrix.com/frontend-ip"         = element(aws_network_interface.client.*.private_ip, 0)
      "ingress.citrix.com/frontend-ipset-name" = var.ipset_name
      "kubernetes.io/ingress.class"            = element(var.ingress_classes, 0)
    }
  }

  spec {
    rule {
      host = var.example_application_hostname
      http {
        path {
          backend {
            service_name = kubernetes_service.apache_service.metadata.0.name
            service_port = kubernetes_service.apache_service.spec.0.port.0.target_port
          }
          path = "/"
        }
      }
    }
  }
}