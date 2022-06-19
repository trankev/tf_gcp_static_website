terraform {
  required_providers {
    google = {
      source = "google"
    }
  }
}
#############################################################################
# Storage
#############################################################################

resource "google_storage_bucket" "website" {
  name          = "website-${var.name}"
  location      = "EU"
  storage_class = "COLDLINE"

  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }
}

data "google_iam_policy" "viewer" {
  binding {
    role = "roles/storage.objectViewer"
    members = [
      "allUsers",
    ]
  }
}

resource "google_storage_bucket_iam_policy" "policy" {
  bucket      = google_storage_bucket.website.name
  policy_data = data.google_iam_policy.viewer.policy_data
}

resource "google_storage_bucket_object" "website" {
  for_each = fileset(var.content_path, "**")
  name     = each.value
  source   = "${var.content_path}/${each.value}"
  bucket   = google_storage_bucket.website.name
}

#############################################################################
# Network
#############################################################################

# Reserve an IP address
resource "google_compute_global_address" "website" {
  name = "${var.name}-lb-ip"
}

data "google_dns_managed_zone" "dns_zone" {
  name = var.dns_zone_name
}

# Add the IP to the DNS
resource "google_dns_record_set" "website" {
  name         = "${var.name}.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas      = [google_compute_global_address.website.address]
}

#############################################################################
# Load balancer
#############################################################################

# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "website" {
  name        = "${var.name}-backend"
  description = "Contains files needed by the website"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}

# Create HTTPS certificate
resource "google_compute_managed_ssl_certificate" "website" {
  name = "${var.name}-cert"
  managed {
    domains = [google_dns_record_set.website.name]
  }
}

# GCP URL MAP
resource "google_compute_url_map" "website" {
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_bucket.website.self_link
}

# GCP target proxy
resource "google_compute_target_https_proxy" "website" {
  name             = "${var.name}-target-proxy"
  url_map          = google_compute_url_map.website.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  name                  = "${var.name}-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website.address
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_target_https_proxy.website.self_link
}
