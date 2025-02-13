packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

variable "vm_template_name" {
  type = string
  default = "debian_cynthion_12_amd64.qcow2"
}

variable "debian_qcow2_file" {
  type = string
  default = "debian-12-generic-amd64.qcow2"
}

variable "qemu_binary_path" {
  type = string 
  default = "qemu-system-x86_64"
}

variable "assets_dir" {
  type = string
  default = "assets/"
}

variable "output_dir" {
  type = string
  default = "artifacts/"
}

variable "user_name" {
  type = string
  default = "user"
}

variable "user_pass" {
  type = string
  default = "user"
}

source "qemu" "debian" {
  iso_url          = "https://cloud.debian.org/images/cloud/bookworm/latest/${var.debian_qcow2_file}"
  iso_checksum     = "file:https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS"
  output_directory = "${var.output_dir}"
  vm_name          = "${var.vm_template_name}"
  qemu_binary      = "${var.qemu_binary_path}"
  memory           = 8192
  accelerator      = "none"
  format           = "qcow2"
  ssh_username     = "${var.user_name}"
  ssh_password     = "${var.user_pass}"
  ssh_timeout      = "-1s"
  disk_interface   = "virtio"
  display          = "none"
  headless         = "true"
  boot_wait        = "10m"
  disk_image       = "true"  
  cd_files         = ["${path.cwd}/${var.assets_dir}/user-data","${path.cwd}/${var.assets_dir}/meta-data"]
  cd_label         = "CIDATA"
}

build {
  sources = ["source.qemu.debian"]
    provisioner "shell" {
      inline = [ 
        "tail -f /var/log/cloud-init-output.log &", 
        "/usr/bin/cloud-init status --wait --long", 
        "kill $(pgrep tail)" 
      ]
    }
}

