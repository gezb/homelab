data "talos_image_factory_urls" "this" {
  talos_version = var.talos_version
  schematic_id  = var.talos_image_factory_schematic_id
  platform      = "nocloud"
}

resource "proxmox_virtual_environment_file" "talos_image" {
  content_type = "iso"
  datastore_id = "isos"
  node_name    = "proxmox2"

  source_file {

    path      = data.talos_image_factory_urls.this.urls.disk_image
    file_name = "talos-${var.talos_version}-nocloud-amd64.iso"
  }

  connection {
    type     = "ssh"
    host     = var.proxmox_hostname
    user     = "root"
    private_key = file(var.proxmox_ssh_key_path)
  }


  # Proxmox won't let you upload a xz archive as a disk image. So trick it by saving the file as *.iso.
  # Afterwards, use a remote-exec provisioner to name it back to *.xz and, finally, extract it. 
  provisioner "remote-exec" {
    inline = [
      "mv /mnt/pve/isos/template/iso/talos-${var.talos_version}-nocloud-amd64.iso /mnt/pve/isos/template/iso/talos-${var.talos_version}-nocloud-amd64.iso.xz",
      "unxz -f /mnt/pve/isos/template/iso/talos-${var.talos_version}-nocloud-amd64.iso.xz"
    ]
  }
}