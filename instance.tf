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


variable "instance_shape" {
  default = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  default = 1
}

variable "instance_shape_config_memory_in_gbs" {
  default = 1
}



variable "flex_instance_image_ocid" {
  type = map(string)
  default = {
    us-ashburn-1 = "ocid1.image.oc1.iad.aaaaaaaaffh3tppq63kph77k3plaaktuxiu43vnz2y5oefkec37kwh7oomea"
    #ap-hyderabad-1 = "ocid1.image.oc1.ap-hyderabad-1.aaaaaaaaekpemzvbfdzhbr7rn56dyd2izcahouohna63qm2uaww5fcrg3viq"
   
  }
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

  timeouts {
    create = "60m"
  }
}






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



output "silver_policy_id" {
  value = data.oci_core_volume_backup_policies.test_predefined_volume_backup_policies.volume_backup_policies[0].id
}



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
