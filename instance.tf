variable "count"{
}

provider "oci" {
  tenancy_ocid         = "ocid1.tenancy.oc1..aaaaaaaauuao4pnrffvzgxylvbobagcyo35qsu6z4bqdvjcla4czevhriqvq"
  user_ocid            = "ocid1.user.oc1..aaaaaaaawimuaayeafktaqctwt4twmobbka5awtsepkd4rvss4mtvykxg3pa"
  fingerprint          = "9c:ed:78:5d:da:35:17:05:0a:6b:93:be:b0:84:38:5c"
  #private_key_path     = "/Users/usman/Desktop/Terraform/Practise-2/mahammad.thotti-11-09-06-09.pem"
  #private_key     = 
  region               = "us-ashburn-1"
  disable_auto_retries = false
}




resource "oci_core_instance" "testhost" {
  # Required
  count = var.count
  availability_domain = "ubQd:US-ASHBURN-AD-2"
  compartment_id      = "ocid1.compartment.oc1..aaaaaaaaywbpujwoxt7wpxvxawpv2xneun36ccmwk4baal7gpjmsswosmrwq"
  shape               = "VM.Standard.E2.1.Micro"
  shape_config {
    memory_in_gbs = 1
    ocpus         = 1
  }
  source_details {
    source_id   = "ocid1.image.oc1.iad.aaaaaaaagubx53kzend5acdvvayliuna2fs623ytlwalehfte7z2zdq7f6ya"
    #source_id = "ocid1.image.oc1.iad.aaaaaaaageeenzyuxgia726xur4ztaoxbxyjlxogdhreu3ngfj2gji3bayda"
    source_type = "image"
  }
  # Optional
  display_name = "testhost${count.index}"
  create_vnic_details {
    assign_public_ip = true
    subnet_id        = "ocid1.subnet.oc1.iad.aaaaaaaa74trcuememyseily3jm5ltzbf7kr4nuv5z3rfaxfiivpln3jeefa"
  }
 # metadata = {
  #ssh_authorized_keys = file(var.ssh_public_key)
    # user_data           = base64encode(file("./bootstrap"))
  #}
  preserve_boot_volume = false
}
