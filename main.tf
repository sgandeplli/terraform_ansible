provider "google" {
  project = "primal-gear-436812-t0"
  region  = "us-central1"
}

resource "google_compute_instance" "centos_vm" {
  name         = "ansible"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-stream-9"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "centos:${file("/root/.ssh/id_rsa.pub")}"
  }

  tags = ["http-server"]
}

output "vm_ip" {
  value = google_compute_instance.centos_vm.network_interface.0.access_config.0.nat_ip
}

resource "null_resource" "update_inventory" {
  provisioner "local-exec" {
    command = <<EOT
      INSTANCE_ID=${google_compute_instance.centos_vm.name}
      INSTANCE_IP=${google_compute_instance.centos_vm.network_interface.0.access_config.0.nat_ip}
      echo 'all:' > /var/lib/jenkins/workspace/terra-ansible/inventory.gcp.yml
      echo '  hosts:' >> /var/lib/jenkins/workspace/terra-ansible/inventory.gcp.yml
      echo "    web_$INSTANCE_ID:" >> /var/lib/jenkins/workspace/terra-ansible/inventory.gcp.yml
      echo "      ansible_host: $INSTANCE_IP" >> /var/lib/jenkins/workspace/terra-ansible/inventory.gcp.yml
      echo "      ansible_user: centos" >> /var/lib/jenkins/workspace/terra-ansible/inventory.gcp.yml
      echo "      ansible_ssh_private_key_file: /root/.ssh/id_rsa" >> /var/lib/jenkins/workspace/terra-ansible/inventory.gcp.yml
    EOT
  }

  depends_on = [google_compute_instance.centos_vm]
}
