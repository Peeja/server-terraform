resource "google_compute_instance" "bastion" {
  count                     = var.enable_bastion ? 1 : 0
  name                      = "${var.unique_name}-bastion"
  machine_type              = "custom-2-4096"
  zone                      = local.zone
  allow_stopping_for_update = true
  labels                    = local.all_labels
  tags                      = ["bastion-host"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = var.network_uri

    access_config {}
  }

  service_account {
    email  = google_service_account.k8s_service_account.email
    scopes = ["cloud-platform"]
  }

  depends_on = [google_container_cluster.circleci_cluster]

  metadata_startup_script = join("\n", [
    "curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.10/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/bin/",
    "echo \"KUBECONFIG=/etc/kube.config gcloud container clusters get-credentials --internal-ip --region ${var.location} ${var.unique_name}-k8s-cluster && ( [ -e /home/ubuntu/.config ] && sudo chown -R ubuntu /home/ubuntu/.config ) && sudo chmod 0644 /etc/kube.config \" > update-kubeconfig && chmod +x update-kubeconfig && sudo mv ./update-kubeconfig /usr/bin/update-kubeconfig && update-kubeconfig",
    "curl -LO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.5.4/kustomize_v3.5.4_linux_amd64.tar.gz && tar xzf ./kustomize_v3.5.4_linux_amd64.tar.gz && sudo mv ./kustomize /usr/bin/",
    "curl -LO https://github.com/replicatedhq/kots/releases/download/v1.19.4/kots_linux_amd64.tar.gz && tar xzf kots_linux_amd64.tar.gz && sudo mv ./kots /usr/bin/kubectl-kots",
    "curl -LO https://github.com/replicatedhq/troubleshoot/releases/download/v0.9.51/preflight_linux_amd64.tar.gz && tar xzf preflight_linux_amd64.tar.gz && sudo mv ./preflight /usr/bin/kubectl-preflight"
  ])
}
