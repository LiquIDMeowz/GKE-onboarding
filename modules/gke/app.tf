resource "null_resource" "create_service_account" {
  provisioner "local-exec" {
    command = <<EOT
      SA_NAME="cloudsql-proxy-test"
      gcloud iam service-accounts create $SA_NAME --display-name $SA_NAME
    EOT
  }
}

resource "null_resource" "get_service_account_email" {
  provisioner "local-exec" {
    command = <<EOT
      SA_NAME="cloudsql-proxy-test"
      SA_EMAIL=$(gcloud iam service-accounts list \
        --filter=displayName:$SA_NAME \
        --format='value(email)')
      echo $SA_EMAIL > sa_email.txt
    EOT
  }

  depends_on = [null_resource.create_service_account]
}

resource "null_resource" "add_cloudsql_role" {
  provisioner "local-exec" {
    command = <<EOT
      PROJECT_ID="gke-project-443004"
      SA_EMAIL=$(cat sa_email.txt)
      gcloud projects add-iam-policy-binding $PROJECT_ID \
        --role roles/cloudsql.client \
        --member serviceAccount:$SA_EMAIL
    EOT
  }

  depends_on = [null_resource.get_service_account_email]
}

resource "null_resource" "create_service_account_key" {
  provisioner "local-exec" {
    command = <<EOT
      SA_EMAIL=$(cat sa_email.txt)
      WORKING_DIR=$(pwd)
      gcloud iam service-accounts keys create $WORKING_DIR/key.json \
        --iam-account $SA_EMAIL
    EOT
  }

  depends_on = [null_resource.add_cloudsql_role]
}

resource "null_resource" "create_mysql_secret" {
  provisioner "local-exec" {
    command = <<EOT
      SQLPASSWORD=$(cat ../../config/sqlpassword)
      kubectl create secret generic cloudsql-db-credentials-test \
        --from-literal=username=wordpress \
        --from-literal=password=$SQLPASSWORD
    EOT
  }

  depends_on = [null_resource.create_service_account_key]
}

resource "null_resource" "create_cloudsql_secret" {
  provisioner "local-exec" {
    command = <<EOT
      WORKING_DIR=$(pwd)
      kubectl create secret generic cloudsql-instance-credentials-test \
        --from-file=$WORKING_DIR/key.json
    EOT
  }

  depends_on = [null_resource.create_mysql_secret]
}

resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    command = <<EOT
      rm -f sa_email.txt key.json
    EOT
  }

  depends_on = [null_resource.create_cloudsql_secret]
}

## TODO 
# Create FS, pv/pvc , deployment , service & ingress for wordpress

resource "google_filestore_instance" "instance" {
  depends_on = [null_resource.cleanup]
  name       = "filestore-instance"
  location   = var.zone
  tier       = "BASIC_HDD"
  deletion_protection_enabled = false
  file_shares {
    capacity_gb = 1024
    name        = "share1"
  }

  networks {
    network = var.vpc_id
    modes   = ["MODE_IPV4"]
  }
}

# data "google_filestore_instance" "instance" {
#   depends_on = [google_filestore_instance.instance]
#   name       = "filestore-instance"
# }

# output "instance_ip_addresses" {
#   depends_on = [data.google_filestore_instance.instance]
#   value      = data.google_filestore_instance.instance.networks[0].ip_addresses[0]
# }

resource "kubernetes_persistent_volume_v1" "example" {
  depends_on = [google_filestore_instance.instance]
  metadata {
    name = "test-pv"
  }
  spec {
    capacity = {
      storage = "1Ti"
    }
    access_modes = ["ReadWriteMany"]
    storage_class_name = "filestore"
    persistent_volume_source {
      nfs {
        read_only = false
        path   = "/share1"
        server = google_filestore_instance.instance.networks[0].ip_addresses[0]
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim_v1" "example" {
  depends_on = [google_filestore_instance.instance]
  metadata {
    name = "test-pvc"
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "filestore"
    resources {
      requests = {
        storage = "20Gi"
      }
    }
    volume_name = kubernetes_persistent_volume_v1.example.metadata.0.name
  }
}

resource "kubernetes_deployment_v1" "wordpress" {
  depends_on = [ google_filestore_instance.instance ]
  metadata {
    name = "wordpress"
    labels = {
      app = "wordpress"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }

      spec {
        container {
          name  = "wordpress"
          image = "wordpress"

          env {
            name  = "WORDPRESS_DB_HOST"
            value = "127.0.0.1:3306"
          }

          env {
            name = "WORDPRESS_DB_USER"
            value_from {
              secret_key_ref {
                name = "cloudsql-db-credentials-test"
                key  = "username"
              }
            }
          }

          env {
            name = "WORDPRESS_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = "cloudsql-db-credentials-test"
                key  = "password"
              }
            }
          }

          port {
            container_port = 80
            name           = "wordpress"
          }

          volume_mount {
            name       = "wordpress-persistent-storage-test"
            mount_path = "/var/www/html"
          }
        }

        container {
          name  = "cloudsql-proxy"
          image = "gcr.io/cloudsql-docker/gce-proxy:1.33.2"
          command = [
            "/cloud_sql_proxy",
            "-instances=gke-project-443004:us-central1:mysql-wordpress-instance=tcp:3306",
            "-credential_file=/secrets/cloudsql/key.json"
          ]

          security_context {
            run_as_user                = 2
            allow_privilege_escalation = false
          }

          volume_mount {
            name       = "cloudsql-instance-credentials-test"
            mount_path = "/secrets/cloudsql"
            read_only  = true
          }
        }

        volume {
          name = "wordpress-persistent-storage-test"
          persistent_volume_claim {
            claim_name = "test-pvc"
          }
        }

        volume {
          name = "cloudsql-instance-credentials-test"
          secret {
            secret_name = "cloudsql-instance-credentials-test"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "wordpress" {
  depends_on = [kubernetes_deployment_v1.wordpress]
  metadata {
    name = "wordpress"
  }

  spec {
    selector = {
      app = "wordpress"
    }

    port {
      port        = 80
      target_port = "wordpress"
    }
  }
}

resource "kubernetes_ingress_v1" "example_ingress" {
  metadata {
    name = "test-ingress"
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "samples.liquidmeow.fun"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "wordpress"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    tls {
      hosts       = ["samples.liquidmeow.fun"]
      secret_name = "self-signed-tls"
    }
  }
}