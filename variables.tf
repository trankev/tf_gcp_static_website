variable "name" {
  type        = string
  description = "Name of the website. Will be used in GCP object names, and as subdomain"
}

variable "dns_zone_name" {
  type        = string
  description = "DNS managed zone to use"
}
