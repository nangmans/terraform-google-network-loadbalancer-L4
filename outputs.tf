output "address" {
    description = "Address of L4 Load Balancer"
    value = {
        for k,v in (
            length(google_compute_global_forwarding_rule.global_external_rule) > 0 ? google_compute_global_forwarding_rule.global_external_rule :
            length(google_compute_forwarding_rule.regional_internal_rule) > 0 ? google_compute_forwarding_rule.regional_internal_rule :
            length(google_compute_forwarding_rule.regional_external_rule) > 0 ? google_compute_forwarding_rule.regional_external_rule :
            length(google_compute_forwarding_rule.regional_internal_proxy_rule) > 0 ? google_compute_forwarding_rule.regional_internal_proxy_rule :
            {}
        ) : k =>v.ip_address
    }
}

output "forwarding_rule_ids" {
    description = "forwarding rule resources ids"
    value = {
        for k,v in (
            length(google_compute_global_forwarding_rule.global_external_rule) > 0 ? google_compute_global_forwarding_rule.global_external_rule :
            length(google_compute_forwarding_rule.regional_internal_rule) > 0 ? google_compute_forwarding_rule.regional_internal_rule :
            length(google_compute_forwarding_rule.regional_external_rule) > 0 ? google_compute_forwarding_rule.regional_external_rule :
            length(google_compute_forwarding_rule.regional_internal_proxy_rule) > 0 ? google_compute_forwarding_rule.regional_internal_proxy_rule :
            {}
        ) : k =>v.id
    }
}

output "target_proxy_ids" {
    description = "Target proxy resources ids"
        value = {
        for k,v in (
            length(google_compute_target_tcp_proxy.proxy) > 0 ? google_compute_target_tcp_proxy.proxy :
            length(google_compute_target_ssl_proxy.proxy) > 0 ? google_compute_target_ssl_proxy.proxy :
            length(google_compute_region_target_tcp_proxy.proxy) > 0 ? google_compute_region_target_tcp_proxy.proxy :
            {}
        ) : k =>v.id
    }
}

output "backend_service_ids" {
    description = "Backend service resources ids"
    value = {
        for k,v in (
            length(google_compute_backend_service.global_external_backend) > 0 ? google_compute_backend_service.global_external_backend :
            length(google_compute_region_backend_service.regional_external_backend) > 0 ? google_compute_region_backend_service.regional_external_backend :
            length(google_compute_region_backend_service.regional_internal_backend) > 0 ? google_compute_region_backend_service.regional_internal_backend :
            length(google_compute_region_backend_service.regional_internal_proxy_backend) > 0 ? google_compute_region_backend_service.regional_internal_proxy_backend :
            {}
        ) : k =>v.id
    }
}

output "health_check_ids" {
    description = "Health check resource ids"
    value = {
        for k,v in (
            length(google_compute_health_check.health_check) > 0 ? google_compute_health_check.health_check :
            length(google_compute_region_health_check.health_check) > 0 ? google_compute_region_health_check.health_check :
            {}
        ) : k =>v.id
    }
}