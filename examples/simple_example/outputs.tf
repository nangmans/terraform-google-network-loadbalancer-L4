output "address" {
    description = "Address of L4 Load Balancer"
    value = module.network_loadbalancer_L4.address
}

output "forwarding_rule_ids" {
    description = "forwarding rule resources ids"
    value = module.network_loadbalancer_L4.forwarding_rule_ids
}

output "target_proxy_ids" {
    description = "Target proxy resources ids"
        value = module.network_loadbalancer_L4.target_proxy_ids
}

output "backend_service_ids" {
    description = "Backend service resources ids"
    value = module.network_loadbalancer_L4.backend_service_ids
}

output "health_check_ids" {
    description = "Health check resource ids"
    value = module.network_loadbalancer_L4.health_check_ids
}
