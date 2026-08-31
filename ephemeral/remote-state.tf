data "terraform_remote_state" "persistent" {
  backend = "s3"
  config = {
    bucket = "green-pulse-tfstate-465853822810"
    key    = "persistent/terraform.tfstate"
    region = "ap-southeast-1"
  }
}