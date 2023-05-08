resource "google_compute_global_forwarding_rule" "global_external_rule" {
    for_each = var.frontend_configs != null && var.lb_type.is_global ? var.frontend_configs : {}
    name = "fr-${var.name}-${each.key}"
    project = var.project_id
    target = each.value.protocol == "TCP" ? lookup(local.tcp_target_proxy, each.key, null).id : each.value.protocol == "SSL" ? lookup(local.ssl_target_proxy, each.key, null).id : null
    description = each.value.description
    ip_address = each.value.ip_address
    ip_protocol = "TCP"
    ip_version = each.value.ip_version
    load_balancing_scheme = "EXTERNAL" 
    port_range = each.value.port.numbers
}

##############################################################################################################################################

resource "google_compute_forwarding_rule" "regional_external_rule" {
    for_each = var.frontend_configs != null && !(var.lb_type.is_global) && var.lb_type.is_external ? var.frontend_configs : {}  
    name = "fr-${var.name}-${each.key}"
    region = var.region
    project = var.project_id
    target = var.lb_type.is_proxied ? (each.value.protocol == "TCP" ? lookup(local.tcp_target_proxy, each.key, null).id : each.value.protocol == "SSL" ? lookup(local.ssl_target_proxy, each.key, null).id : null) : null
    backend_service = var.lb_type.is_proxied ? null : local.region_external_backend_service.id
    description = each.value.description
    ip_address = each.value.ip_address
    network_tier = "STANDARD"
    ip_protocol = "TCP"
    load_balancing_scheme = "EXTERNAL" 
    port_range = var.lb_type.is_proxied ? each.value.port.numbers : null
    ports = var.lb_type.is_proxied ? null : each.value.port.numbers
    all_ports = try(each.value.port.all, false)
    dynamic "service_directory_registrations" {
        for_each = each.value.service_directory_registration != null ? [""] : []
        content {
            namespace = each.value.service_directory_registration.namespace
            service = each.value.service_directory_registration.service
        }
    }
}

##############################################################################################################################################

resource "google_compute_forwarding_rule" "regional_internal_proxy_rule" {
    for_each = var.frontend_configs != null && local.is_region_internal_proxy_lb ? var.frontend_configs : {}
    name = "fr-${var.name}-${each.key}"
    region = var.region
    subnetwork = each.value.subnet
    network = var.network
    project = var.project_id
    allow_global_access = each.value.allow_global_access
    target = each.value.protocol == "TCP" ? lookup(local.region_tcp_target_proxy, each.key, null).id : each.value.protocol == "SSL" ? lookup(local.ssl_target_proxy, each.key, null).id : null
    description = each.value.description
    ip_address = each.value.ip_address
    ip_protocol = "TCP"
    load_balancing_scheme = "INTERNAL_MANAGED" 
    port_range = join(", ",each.value.port.numbers)
    dynamic "service_directory_registrations" {
        for_each = each.value.service_directory_registration != null ? [""] : []
        content {
            namespace = each.value.service_directory_registration.namespace
            service = each.value.service_directory_registration.service
        }
    }
}

##############################################################################################################################################

resource "google_compute_forwarding_rule" "regional_internal_rule" {
    for_each = var.frontend_configs != null && local.is_region_internal_nonproxy_lb ? var.frontend_configs : {}
    name = "fr-${var.name}-${each.key}"
    region = var.region
    subnetwork = each.value.subnet
    network = var.network
    project = var.project_id
    backend_service = local.region_internal_backend_service.id
    allow_global_access = each.value.allow_global_access
    is_mirroring_collector = each.value.enable_packet_mirroring
    service_label = each.value.service_label
    description = each.value.description
    ip_address = each.value.ip_address
    ip_protocol = "TCP"
    load_balancing_scheme = "INTERNAL" 
    ports =  each.value.port.numbers
    all_ports = try(each.value.port.all, false)
    dynamic "service_directory_registrations" {
        for_each = each.value.service_directory_registration != null ? [""] : []
        content {
            namespace = each.value.service_directory_registration.namespace
            service = each.value.service_directory_registration.service
        }
    }
}
