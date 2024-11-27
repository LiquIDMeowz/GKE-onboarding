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
      SQLPASSWORD=$(cat /home/meow/ProjectX/config/sqlpassword)
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
# Create pv/pvc , deployment , service & ingress for wordpress