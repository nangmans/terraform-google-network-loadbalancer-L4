 locals {
    is_region_external_proxy_lb = !(var.lb_type.is_global) && var.lb_type.is_external && var.lb_type.is_proxied
    is_region_internal_proxy_lb = !(var.lb_type.is_global) && !(var.lb_type.is_external) && var.lb_type.is_proxied
    is_region_internal_nonproxy_lb = !(var.lb_type.is_global) && !(var.lb_type.is_external) && !(var.lb_type.is_proxied)
    is_region_external_nonproxy_lb = !(var.lb_type.is_global) && var.lb_type.is_external && !(var.lb_type.is_proxied)
    is_global_external_lb = var.lb_type.is_global && var.lb_type.is_external
    is_region_external_lb = !(var.lb_type.is_global) && var.lb_type.is_external
    is_region_internal_lb = !(var.lb_type.is_global) && !(var.lb_type.is_external)
    tcp_target_proxy = {for k,v in google_compute_target_tcp_proxy.proxy : k => v}
    ssl_target_proxy = {for k,v in google_compute_target_ssl_proxy.proxy : k => v}
    region_tcp_target_proxy = {for k,v in google_compute_region_target_tcp_proxy.proxy : k => v}
    proxy_ssl_cert = concat(
        coalesce(var.frontend_ssl_certs.certificate_ids,[]),
        [for k,v in google_compute_ssl_certificate.cert: v.id],
        [for k,v in google_compute_managed_ssl_certificate.cert : v.id]
    )
    global_external_backend_service = lookup({for k,v in google_compute_backend_service.global_external_backend : k => v}, keys(var.backend_services)[0], null)
    region_internal_proxy_backend_service = lookup({for k,v in google_compute_region_backend_service.regional_internal_proxy_backend : k => v}, keys(var.backend_services)[0], null)
    region_internal_backend_service = lookup({for k,v in google_compute_region_backend_service.regional_internal_backend : k => v}, keys(var.backend_services)[0], null)
    region_external_backend_service = lookup({for k,v in google_compute_region_backend_service.regional_external_backend : k => v}, keys(var.backend_services)[0], null)

    module_name    = "terraform-google-network-loadbalancer-L4"
    module_version = "v0.0.1"
 }