// Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Mozilla Public License v2.0

variable "tenancy_ocid" {
}

variable "user_ocid" {
}

variable "fingerprint" {
}

variable "private_key" {
}

variable "region" {
}

variable "compartment_ocid" {
}

variable "ssh_public_key" {
}

variable "ssh_private_key" {
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key      = var.private_key
  region           = var.region
}

# Defines the number of instances to deploy
variable "num_instances" {
  default = "3"
}

# Defines the number of volumes to create and attach to each instance
# NOTE: Changing this value after applying it could result in re-attaching existing volumes to different instances.
# This is a result of using 'count' variables to specify the volume and instance IDs for the volume attachment resource.
variable "num_iscsi_volumes_per_instance" {
  default = "1"
}

variable "num_paravirtualized_volumes_per_instance" {
  default = "2"
}

variable "instance_shape" {
  default = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  default = 1
}

variable "instance_shape_config_memory_in_gbs" {
  default = 1
}

variable "instance_image_ocid" {
  type = map(string)

  default = {
    # See https://docs.us-phoenix-1.oraclecloud.com/images/
    # Oracle-provided image "Oracle-Linux-7.5-2018.10.16-0"
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaaoqj42sokaoh42l76wsyhn3k2beuntrh5maj3gmgmzeyr55zzrwwa"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaageeenzyuxgia726xur4ztaoxbxyjlxogdhreu3ngfj2gji3bayda"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaitzn6tdyjer7jl34h2ujz74jwy5nkbukbh55ekp6oyzwrtfa4zma"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaa32voyikkkzfxyo4xbdmadc2dmvorfxxgdhpnk6dw64fa3l4jh7wa"
  }
}

variable "flex_instance_image_ocid" {
  type = map(string)
  default = {
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaaffh3tppq63kph77k3plaaktuxiu43vnz2y5oefkec37kwh7oomea"
    #ap-hyderabad-1 = "ocid1.image.oc1.ap-hyderabad-1.aaaaaaaaekpemzvbfdzhbr7rn56dyd2izcahouohna63qm2uaww5fcrg3viq"
   
  }
}

variable "db_size" {
  default = "50" # size in GBs
}

variable "tag_namespace_description" {
  default = "Just a test"
}

variable "tag_namespace_name" {
  default = "testexamples-tag-namespace"
}

resource "oci_core_instance" "test_instance" {
  count               = var.num_instances
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "TestInstance-usman${count.index}"
  shape               = var.instance_shape

  shape_config {
    ocpus = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  create_vnic_details {
    subnet_id                 = oci_core_subnet.test_subnet.id
    display_name              = "Primaryvnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    hostname_label            = "exampleinstance${count.index}"
  }

  source_details {
    source_type = "image"
    source_id = var.flex_instance_image_ocid[var.region]
    # Apply this to set the size of the boot volume that is created for this instance.
    # Otherwise, the default boot volume size of the image is used.
    # This should only be specified when source_type is set to "image".
    #boot_volume_size_in_gbs = "60"
  }

  # Apply the following flag only if you wish to preserve the attached boot volume upon destroying this instance
  # Setting this and destroying the instance will result in a boot volume that should be managed outside of this config.
  # When changing this value, make sure to run 'terraform apply' so that it takes effect before the resource is destroyed.
  #preserve_boot_volume = true

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    #user_data           = base64encode(file("./userdata/bootstrap"))
  }
#   defined_tags = {
#     "${oci_identity_tag_namespace.tag-namespace1.name}.${oci_identity_tag.tag2.name}" = "awesome-app-server"
#   }

  freeform_tags = {
    "freeformkey${count.index}" = "freeformvalue${count.index}"
  }

  preemptible_instance_config {
    preemption_action {
      type = "TERMINATE"
      preserve_boot_volume = false
    }
  }

  timeouts {
    create = "60m"
  }
}

# Define the volumes that are attached to the compute instances.

resource "oci_core_volume" "test_block_volume" {
  count               = var.num_instances * var.num_iscsi_volumes_per_instance
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "TestBlock-usman${count.index}"
  size_in_gbs         = var.db_size
}



resource "oci_core_volume_attachment" "test_block_attach" {
  count           = var.num_instances * var.num_iscsi_volumes_per_instance
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.test_instance[floor(count.index / var.num_iscsi_volumes_per_instance)].id
  volume_id       = oci_core_volume.test_block_volume[count.index].id
  device          = count.index == 0 ? "/dev/oracleoci/oraclevdb" : ""

  # Set this to enable CHAP authentication for an ISCSI volume attachment. The oci_core_volume_attachment resource will
  # contain the CHAP authentication details via the "chap_secret" and "chap_username" attributes.
  use_chap = true
  # Set this to attach the volume as read-only.
  #is_read_only = true
}

resource "oci_core_volume" "test_block_volume_paravirtualized" {
  count               = var.num_instances * var.num_paravirtualized_volumes_per_instance
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "TestBlockParavirtualized-usman${count.index}"
  size_in_gbs         = var.db_size
}

resource "oci_core_volume_attachment" "test_block_volume_attach_paravirtualized" {
  count           = var.num_instances * var.num_paravirtualized_volumes_per_instance
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.test_instance[floor(count.index / var.num_paravirtualized_volumes_per_instance)].id
  volume_id       = oci_core_volume.test_block_volume_paravirtualized[count.index].id
  # Set this to attach the volume as read-only.
  #is_read_only = true
}

resource "oci_core_volume_backup_policy_assignment" "policy" {
  count     = var.num_instances
  asset_id  = oci_core_instance.test_instance[count.index].boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.test_predefined_volume_backup_policies.volume_backup_policies[0].id
}

# resource "null_resource" "remote-exec" {
#   depends_on = [
#     oci_core_instance.test_instance,
#     oci_core_volume_attachment.test_block_attach,
#   ]
#   count = var.num_instances * var.num_iscsi_volumes_per_instance

#   provisioner "remote-exec" {
#     connection {
#       agent       = false
#       timeout     = "30m"
#       host        = oci_core_instance.test_instance[count.index % var.num_instances].public_ip
#       user        = "opc"
#       private_key = "-----BEGIN RSA PRIVATE KEY-----MIIEowIBAAKCAQEAzjlSmAtzSOhUHetzU5RBobxrpO/h+vVQmFywuiRiIWjUBm9A5xLpHA1ZTjSJ62NDhSg9TWBRj8LofguuZoL92n/nwnq1HnVmcBSs7qPrzYpEPQziOziKQjd2B4GVuNzpiudRtoX5ou0BY8jaSXVJMNhkG/iJT95VQBeHEOT39S2X5/KCVXw6QJWbiKkeTAQ3KIv3TRDtmuqPlpubQjq5E7ji4zhanVhtLoALGcs/ysCGS/f5LOABnjPkaya/CgOgpOF5UhutrDA+KYeRmUl0GLL6HSY8qQvF5wG+p1uSxxKuimEqKBv1AYM1FVtG7MRUKBztZxrc2Zp9CiXeRrt67QIDAQABAoIBAA/s41D0iWmW73AED7rjlxHrYBCzqarcqOWrOsaVKrLTypPYoZV2o2PUMBJXAlOYLc2pptpD1uiYL6YUNtqZwQrPl9Ev8q6weEGthxFCvWH5DH3+cbYLDrpAWDAKNMq63JoqdOf4fqezT8kp6JmFoipQe6KhVdFCJSk25+pJFFDtmefkTHX4K46oWbIAE59qDQxvF7QK5llvqSQkpEXieqkRiJFqOfrKtMxLrcjLPSna9+2t8/ZYbGzhUncp2UjExjyHoOUDGkNSx8g+86WfitdwbiGxC15xjGlOUwhWC3bZDLAFeQxKhFiY1n9/Ky4YNXf2l10oCy9L03RYC2pwRaECgYEA8LIRnat1x4o3wqLYuyPMiDf3RYQ1430Ety9SsoZkbmGguI7SkZzdkiM9fDZ4yNYf9Shsq2weXUNFWK4Ue2s3tR9JD8+XKyAW30q1A9KHMWNdkSEJJDaoYBSBNIPYMo4ETp/wr8dQqSuY+vdt+YK8OyXIhBHg54gmR8dISi0CcUkCgYEA21Yj2N1ir0TQC6pKG9xpB2J8gkfJxVuO0EUAJl4emQVYEeaXsMWRFQ/9nBDyW/14+LMnrG3U4AcUAqJl9Mfq4GDUFBfwioSPYAhQW99iFDk9dJzbb5OTJ8Ox1z6FQe3dLldJHvychoGIi/FuThvpd3BLPUm5NSL3vHXt0+lhoIUCgYBnzeQbA58/9zQlFOYzjzTeaoSRznsPKROnjRk1NRCLKj+OWMonUmecZuZVc4iT1QTjThPPukk+H40AudLLh2n3Cw8Pao/fYW97zVRT2a/EdP4dYQn4PDpRdYZjh5jt9KGW5xN+O49l5g+L7LnZKbDUMW9QxgUg1W7s9d0PYGn1QQKBgF6W5Hi26MMbUvlk4/bl8+l6YKWyneJd3NYWm7zwJBPryRJXNp3GZg4GSmHOsSZYxp3CbV6gMwi2JLwKGxwYR0OinnNX66VhC4/npfgo+twr30P2DXAt3W1tqLlhvggzs4oznFYfrMUZAbEQWniW8vVOWTRCIfw3a008MmeMI00dAoGBAOsDPBnKINHCKWkP+PKZKz1uIlW7Wln+ef/89RoLk1sB8xz9Ayl+I5z22fN72iiBG96lAqEIXdb+tERBcaaNfs3/LjawMvfsBZONG7mASrfLQoYMl+x95FG/55gyllYebXA2j0w/X8zk9rBbRmzjPinjUKAHS4bLQ61KIuKl/Os3-----END RSA PRIVATE KEY-----"
#     }

#     inline = [
#       "touch ~/IMadeAFile.Right.Here",
#       "sudo iscsiadm -m node -o new -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port}",
#       "sudo iscsiadm -m node -o update -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -n node.startup -v automatic",
#       "sudo iscsiadm -m node -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port} -o update -n node.session.auth.authmethod -v CHAP",
#       "sudo iscsiadm -m node -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port} -o update -n node.session.auth.username -v ${oci_core_volume_attachment.test_block_attach[count.index].chap_username}",
#       "sudo iscsiadm -m node -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port} -o update -n node.session.auth.password -v ${oci_core_volume_attachment.test_block_attach[count.index].chap_secret}",
#       "sudo iscsiadm -m node -T ${oci_core_volume_attachment.test_block_attach[count.index].iqn} -p ${oci_core_volume_attachment.test_block_attach[count.index].ipv4}:${oci_core_volume_attachment.test_block_attach[count.index].port} -l",
#     ]
#   }
# }

/*
# Gets the boot volume attachments for each instance
data "oci_core_boot_volume_attachments" "test_boot_volume_attachments" {
  depends_on          = [oci_core_instance.test_instance]
  count               = var.num_instances
  availability_domain = oci_core_instance.test_instance[count.index].availability_domain
  compartment_id      = var.compartment_ocid

  instance_id = oci_core_instance.test_instance[count.index].id
}
*/

data "oci_core_instance_devices" "test_instance_devices" {
  count       = var.num_instances
  instance_id = oci_core_instance.test_instance[count.index].id
}

data "oci_core_volume_backup_policies" "test_predefined_volume_backup_policies" {
  filter {
    name = "display_name"

    values = [
      "silver",
    ]
  }
}

# Output the private and public IPs of the instance

output "instance_private_ips" {
  value = [oci_core_instance.test_instance.*.private_ip]
}

output "instance_public_ips" {
  value = [oci_core_instance.test_instance.*.public_ip]
}

# Output the boot volume IDs of the instance
output "boot_volume_ids" {
  value = [oci_core_instance.test_instance.*.boot_volume_id]
}

# Output all the devices for all instances
output "instance_devices" {
  value = [data.oci_core_instance_devices.test_instance_devices.*.devices]
}

# Output the chap secret information for ISCSI volume attachments. This can be used to output
# CHAP information for ISCSI volume attachments that have "use_chap" set to true.
#output "IscsiVolumeAttachmentChapUsernames" {
#  value = [oci_core_volume_attachment.test_block_attach.*.chap_username]
#}
#
#output "IscsiVolumeAttachmentChapSecrets" {
#  value = [oci_core_volume_attachment.test_block_attach.*.chap_secret]
#}

output "silver_policy_id" {
  value = data.oci_core_volume_backup_policies.test_predefined_volume_backup_policies.volume_backup_policies[0].id
}

/*
output "attachment_instance_id" {
  value = data.oci_core_boot_volume_attachments.test_boot_volume_attachments.*.instance_id
}
*/

resource "oci_core_vcn" "test_vcn" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "TestVcn-usman"
  dns_label      = "testvcn"
}

resource "oci_core_internet_gateway" "test_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "TestInternetGateway"
  vcn_id         = oci_core_vcn.test_vcn.id
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.test_vcn.default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.test_internet_gateway.id
  }
}

resource "oci_core_subnet" "test_subnet" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  cidr_block          = "10.1.20.0/24"
  display_name        = "TestSubnet"
  dns_label           = "testsubnet"
  security_list_ids   = [oci_core_vcn.test_vcn.default_security_list_id]
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.test_vcn.id
  route_table_id      = oci_core_vcn.test_vcn.default_route_table_id
  dhcp_options_id     = oci_core_vcn.test_vcn.default_dhcp_options_id
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}
