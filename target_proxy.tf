resource "google_compute_target_tcp_proxy" "proxy" {
    for_each =  (var.lb_type.is_external && var.lb_type.is_proxied) ? {
        for k,v in var.frontend_configs :  k => v if v.protocol == "TCP" 
        } : {}
    name = "tp-${var.name}-${each.key}"
    backend_service = local.global_external_backend_service.id
    proxy_header = try(each.value.enable_proxy_protocol ? "PROXY_V1" : "NONE", null)
    description = "This target proxy is created by terraform"
    project = var.project_id
}

resource "google_compute_target_ssl_proxy" "proxy" {
    for_each = {
        for k,v in var.frontend_configs :  k => v if v.protocol == "SSL" 
        } 
    name = "tp-${var.name}-${each.key}"
    backend_service = local.global_external_backend_service.id
    description = "This target proxy is created by terraform"
    ssl_certificates = local.proxy_ssl_cert
    certificate_map = each.value.certificate_map
    proxy_header = coalesce(each.value.enable_proxy_protocol, false)  ? "PROXY_V1" : "NONE"
    ssl_policy = each.value.ssl_policy
    project = var.project_id

}

resource "google_compute_region_target_tcp_proxy" "proxy" {
    for_each =  (var.lb_type.is_external || !(var.lb_type.is_proxied)) ? {} : {
        for k,v in var.frontend_configs :  k => v if v.protocol == "TCP" 
        } 
    provider = google-beta
    name = "tp-${var.name}-${each.key}"
    region = var.region
    backend_service = local.region_internal_proxy_backend_service.id
    proxy_header = try(each.value.enable_proxy_protocol ? "PROXY_V1" : "NONE", null)
    description = "This target proxy is created by terraform"
    project = var.project_id
}
