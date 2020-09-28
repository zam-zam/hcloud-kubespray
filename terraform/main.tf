variable "hcloud_token" {}

variable "server_location" {
    type = string
    default = "fsn1"
}

variable "server_type" {
    type = string
    default = "cpx11"
}

variable "node_count" {
    type = number
    default = 1
}

variable "os_image" {
    type = string
    default = "ubuntu-20.04"
}

provider "hcloud" {
    token = var.hcloud_token
}

data "hcloud_ssh_key" "zzamzam" {
    fingerprint = "df:6f:cc:e6:82:32:97:c3:d0:b9:02:3d:70:31:c0:e0"
}

resource "hcloud_server" "kube-node" {
    count = var.node_count
    name = "kube-node-${count.index + 1}"
    image = var.os_image
    server_type = var.server_type
    location = var.server_location
    ssh_keys  = [data.hcloud_ssh_key.zzamzam.id]
}

resource "hcloud_network" "internal-1" {
    name = "internal-1"
    ip_range = "192.168.0.0/21"
}

resource "hcloud_network_subnet" "k8s-subnet" {
    network_id = hcloud_network.internal-1.id
    type = "server"
    ip_range = "192.168.1.0/24"
    network_zone = "eu-central"
}

resource "hcloud_server_network" "kubenetwork" {
    network_id = hcloud_network.internal-1.id
    server_id  = element(hcloud_server.kube-node.*.id, count.index)
    ip         = cidrhost(hcloud_network_subnet.k8s-subnet.ip_range, count.index + 1)
    count      = var.node_count
}

output "public_ips" {
    value = hcloud_server.kube-node.*.ipv4_address
}

output "private_ips" {
    value = hcloud_server_network.kubenetwork.*.ip
}
