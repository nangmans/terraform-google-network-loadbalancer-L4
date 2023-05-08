resource "google_compute_managed_ssl_certificate" "cert" {
  for_each = var.frontend_ssl_certs.managed_cert != null ? var.frontend_ssl_certs.managed_cert : null
  name        = each.key
  description = each.value.description
  project     = var.project_id
  managed {
    domains = each.value.domains
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_ssl_certificate" "cert" {
  for_each = var.frontend_ssl_certs.custom_cert != null ? var.frontend_ssl_certs.custom_cert : null
  name        = each.key
  description = each.value.description
  project     = var.project_id
  certificate = each.value.certificate
  private_key = each.value.private_key
}