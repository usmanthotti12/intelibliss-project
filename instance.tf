variable "count_of_instances"{
}



provider "oci" {
  tenancy_ocid         = "ocid1.tenancy.oc1..aaaaaaaauuao4pnrffvzgxylvbobagcyo35qsu6z4bqdvjcla4czevhriqvq"
  user_ocid            = "ocid1.user.oc1..aaaaaaaawimuaayeafktaqctwt4twmobbka5awtsepkd4rvss4mtvykxg3pa"
  fingerprint          = "9c:ed:78:5d:da:35:17:05:0a:6b:93:be:b0:84:38:5c"
  #private_key_path     = "/Users/usman/Desktop/Terraform/Practise-2/mahammad.thotti-11-09-06-09.pem"
  private_key     = "-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCOx0MsqumMJkwY
7Ecm1gDch4cd8uhTqtM+Yo8z6o+tp2Aq3nVvvyLqR2pNpYZDAoa5Gm1CDrfCsyeb
NLnjLlgg1nFzkzqdxSioLChW2AM1HK9KrAp5fLU8NFikP4eiHMzbPjDXAwVg6q+l
bJHTH5K1tlBhM+/LO3NkIwtlGMA0l96EDtO/i6FJip/ILMZkPErufu5BvXLnpuGk
GaiNzUYWaZ0NIkxoTQKLjSB3uIlAwr+pJFItG6PC+sQjZNH4oMjPB+jDiQ7E6pR0
4gBiHD4w1zawltEgP3nBxWUhto3EikE46MFbWuhybaYpbprqgrSAtfY0HzgbkDJ0
aUiAM99dAgMBAAECggEAQR2tjDSSeQGKWR+BP7v//pOs0sLSpD3XQ69tgg7q4hbg
rAxy4Lj6MoDJgYoJFoyTZt4fkC3oLtrIKGe+k1ayiJ9kdIJkDEo7xZ8F8r1nkRR4
+YRG7qsqeL+i4Z27vPqHj0Howla1YEMIQlimlPPkVA1G0V3/cd+2O6gj7UKBfjpK
kVIZcUYwES0r5UxTc/JDf2N9pxkGHxUhNSWpGcnzRhlwk0NyrlC1z6YqhBe/hdxC
0GYGPOuiuPZtNTlrV4hG3W7jAlGGGPIKYGKmzmCUULjIAwL6Exw++pNvZA2FOvNd
a5l12bggEETaJTd9w1YSCj8nLefsYuV6z9jdXdNC3QKBgQDHBjZSdv+v9YD2oDKu
uyDOnKDkE4IipvmhmSfA+C+YQGkUQo/O9jALVlivpWSH+aa4QiemXdYfrep9/VUl
nOYhtKuJVtYbbguvR6PHe2rtvssWBXiJ50vXSZd1nL5IXHC2guyI5O3qS89TdAe0
BLVizQ1zyuiaf8+4YCrTr34rOwKBgQC3pvyDr9xzdByY8ESizj06X0ErxrEfnplB
xUCh2BsUOvpEfN7A44cgx4V25FjA2LDosOePu+YHDbJFe8zg3MGCipcoxyq0AWqP
83r0iO2SYpHN4XRzPvYrTBd6eWQCFN5LXUCrGpmv2sagZI0eh2q5U8nMStl1v5Jq
qvT3cW+GRwKBgQCwDojDTk1E5JIemPv8ocCVxOx2leNKsBanowoNo/7GWkQaDf+U
/yblAI8XYeGaf3fCC5NzkhK2l2yV4yINUcwqCN6tcUmZnjFr7p2s+zpN8bdJVbGZ
nCf03D7FZdDVxiBW8142gv0Lg+B1XHDsCDZEnkvGILq+4U1pNnjsJZQgvQKBgFCn
p5J1841I2x5Xtu0BQmaWWtrM4hEO6CO4a1Aoxou18x+M748q3beJqJW0Zz4abGdk
+e1oCffjDf3yBuJiUSHxl70y6xAu5wvdVIx8bkmxvHL8ptXOOvJ88nq5QTCg1Zen
lrUOc5yFqmHahxd3RWmq4J816BcMUVNDTV42lVIVAoGAYxjXRsqiEYlwDbDNNqu7
FbL7dso2jYVFD5fWorSjONYr3XwddPlBcgpEdwIzRDmbJIhh3TW0d/ynmWRbt7pg
1nByXhYw9wg3R05x6hIHuvMy1ooSaxgFfZ/99vGYx0ZMZua/++FHG4v97han1c/V
TrPy2a9ZCM7YxNHzOQpgsP8=
-----END PRIVATE KEY-----"
  region               = "us-ashburn-1"
  disable_auto_retries = false
}




resource "oci_core_instance" "testhost" {
  # Required
  count = var.count_of_instances
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
