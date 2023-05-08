resource "google_compute_backend_service" "global_external_backend" {
  for_each = var.backend_services != null && var.lb_type.is_external && var.lb_type.is_proxied ? var.backend_services : {}
  name = "lb-${var.name}"
  project = var.project_id
  description = each.value.description
  protocol = each.value.protocol
  timeout_sec = each.value.timeout_sec
  port_name = each.value.named_port == null ? lower(each.value.protocol) : each.value.named_port
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  custom_request_headers = each.value.custom_request_headers
  custom_response_headers = each.value.custom_response_headers
  health_checks =  ["https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/healthChecks/${each.value.health_check.0}"]
  load_balancing_scheme = "EXTERNAL" 
  session_affinity = each.value.session_affinity
  dynamic "backend" {
    for_each = {
      for k,v in each.value.backends :
      k => v
    }
    iterator = backend
    content {
      group = backend.value.group
      description = backend.value.description
      balancing_mode = (each.value.backend_type == "NEG" || backend.value.balancing_mode.connection != null) ? "CONNECTION" : backend.value.balancing_mode.utilization != null ? "UTILIZATION" : null
      max_utilization = try(backend.value.balancing_mode.utilization.max_utilization, null)
      max_connections = try(backend.value.balancing_mode.utilization.max_connections,
      backend.value.balancing_mode.connection.max_connections , null)
      max_connections_per_instance = try(backend.value.balancing_mode.utilization.max_connections_per_instance,
      backend.value.balancing_mode.connection.max_connections_per_instance, null)
      capacity_scaler = backend.value.balancing_mode.capacity
    }
  }
  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    iterator = config
    content {
      enable = config.value.enable
      sample_rate = config.value.sample_rate
    }
  }
  dynamic "iap" {
    for_each = each.value.iap_config != null ? [each.value.iap_config] : []
    iterator = iap
    content {
      oauth2_client_id = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
      oauth2_client_secret_sha256 = iap.value.oauth2_client_secret_sha256
    }
  }

  depends_on = [
    google_compute_health_check.health_check
  ]
}

##############################################################################################################################################

resource "google_compute_region_backend_service" "regional_external_backend" {
  for_each = var.backend_services != null  && local.is_region_external_nonproxy_lb ? var.backend_services : {} 
  name = "lb-${var.name}"
  project = var.project_id
  region  = var.region
  description = each.value.description
  protocol = each.value.protocol
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  health_checks = ["https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/healthChecks/${each.value.health_check.0}"]
  load_balancing_scheme = "EXTERNAL" 
  session_affinity = each.value.session_affinity
  dynamic "backend" {
    for_each = {
      for k,v in each.value.backends :
      k => v
    }
    iterator = backend
    content {
      group = backend.value.group
      description = backend.value.description
      failover = backend.value.enable_failover
    }
  }
  dynamic "failover_policy" {
    for_each = each.value.failover_policy != null ? [""] : []
    content {
      disable_connection_drain_on_failover = each.value.failover_policy.disable_connection_drain_on_failover
      drop_traffic_if_unhealthy = each.value.failover_policy.drop_traffic_if_unhealthy
      failover_ratio = each.value.failover_policy.failover_ratio
    }
  }
  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    iterator = config
    content {
      enable = config.value.enable
      sample_rate = config.value.sample_rate
    }
  }
  dynamic "iap" {
    for_each = each.value.iap_config != null ? [each.value.iap_config] : []
    iterator = iap
    content {
      oauth2_client_id = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
      oauth2_client_secret_sha256 = iap.value.oauth2_client_secret_sha256
    }
  }

  depends_on = [
    google_compute_region_health_check.health_check
  ]
}

##############################################################################################################################################

resource "google_compute_region_backend_service" "regional_internal_backend" {
  for_each = var.backend_services != null && local.is_region_internal_nonproxy_lb ? var.backend_services : {} 
  name = "lb-${var.name}"
  project = var.project_id
  region  = var.region
  description = each.value.description
  protocol = each.value.protocol
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  health_checks = ["https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/healthChecks/${each.value.health_check.0}"]
  load_balancing_scheme = "INTERNAL" 
  session_affinity = each.value.session_affinity
  dynamic "backend" {
    for_each = {
      for k,v in each.value.backends :
      k => v
    }
    iterator = backend
    content {
      group = backend.value.group
      description = backend.value.description
      failover = backend.value.enable_failover
    }
  }
  dynamic "failover_policy" {
    for_each = each.value.failover_policy != null ? [""] : []
    content {
      disable_connection_drain_on_failover = each.value.failover_policy.disable_connection_drain_on_failover
      drop_traffic_if_unhealthy = each.value.failover_policy.drop_traffic_if_unhealthy
      failover_ratio = each.value.failover_policy.failover_ratio
    }
  }
  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    iterator = config
    content {
      enable = config.value.enable
      sample_rate = config.value.sample_rate
    }
  }
  dynamic "iap" {
    for_each = each.value.iap_config != null ? [each.value.iap_config] : []
    iterator = iap
    content {
      oauth2_client_id = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
      oauth2_client_secret_sha256 = iap.value.oauth2_client_secret_sha256
    }
  }

  depends_on = [
    google_compute_region_health_check.health_check
  ]
}

##############################################################################################################################################

resource "google_compute_region_backend_service" "regional_internal_proxy_backend" {
  for_each = var.backend_services != null && local.is_region_internal_proxy_lb ? var.backend_services : {} 
  name = "lb-${var.name}"
  project = var.project_id
  region  = var.region
  description = each.value.description
  protocol = each.value.protocol
  timeout_sec = each.value.timeout_sec
  port_name = each.value.named_port == null ? lower(each.value.protocol) : each.value.named_port
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  health_checks = ["https://www.googleapis.com/compute/v1/projects/${var.project_id}/regions/${var.region}/healthChecks/${each.value.health_check.0}"]
  load_balancing_scheme = "INTERNAL_MANAGED" 
  locality_lb_policy = each.value.locality_lb_policy
  session_affinity = each.value.session_affinity
  dynamic "backend" {
    for_each = {
      for k,v in each.value.backends :
      k => v
    }
    iterator = backend
    content {
      group = backend.value.group
      failover = backend.value.enable_failover
      description = backend.value.description
      balancing_mode = (each.value.backend_type == "NEG" || backend.value.balancing_mode.connection != null) ? "CONNECTION" : backend.value.balancing_mode.utilization != null ? "UTILIZATION" : null
      max_utilization = try(backend.value.balancing_mode.utilization.max_utilization, null)
      max_connections = try(backend.value.balancing_mode.utilization.max_connections,
      backend.value.balancing_mode.connection.max_connections , null)
      max_connections_per_instance = try(backend.value.balancing_mode.utilization.max_connections_per_instance,
      backend.value.balancing_mode.connection.max_connections_per_instance, null)
      capacity_scaler = backend.value.balancing_mode.capacity
    }
  }
  dynamic "circuit_breakers" {
    for_each = each.value.circuit_breakers != null ? [each.value.circuit_breakers] : []
    iterator = config
    content {
      max_connections = config.value.max_connections
      max_requests_per_connection = config.value.max_requests_per_connection
      max_pending_requests = config.value.max_pending_requests
      max_requests = config.value.max_requests
      max_retries = config.value.max_retries
    }
  }
  dynamic "log_config" {
    for_each = each.value.log_config != null ? [each.value.log_config] : []
    iterator = config
    content {
      enable = config.value.enable
      sample_rate = config.value.sample_rate
    }
  }
  dynamic "outlier_detection" {
    for_each = each.value.outlier_detection != null ? [each.value.outlier_detection] : []
    iterator = config
    content {
      max_ejection_percent = config.value.max_ejection_percent
      success_rate_minimum_hosts = config.value.success_rate_minimum_hosts
      success_rate_stdev_factor = config.value.success_rate_stdev_factor
      success_rate_request_volume = config.value.success_rate_request_volume
      enforcing_consecutive_errors = config.value.enforcing_consecutive_errors
      enforcing_consecutive_gateway_failure = config.value.enforcing_consecutive_gateway_failure
      enforcing_success_rate = config.value.enforcing_success_rate
      consecutive_gateway_failure = config.value.consecutive_gateway_failure
      consecutive_errors = config.value.consecutive_errors
      dynamic "interval" {
        for_each = config.value.interval != null ? [config.value.interval] : []
        content {
          seconds = interval.value.seconds
          nanos = interval.value.nanos
        }
      }
      dynamic "base_ejection_time" {
        for_each = config.value.base_ejection_time != null ? [config.value.base_ejection_time]  : []
        iterator = time
        content {
          seconds = time.value.seconds
          nanos = time.value.nanos
        }
      }
    }
  }
  dynamic "iap" {
    for_each = each.value.iap_config != null ? [each.value.iap_config] : []
    iterator = iap
    content {
      oauth2_client_id = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
      oauth2_client_secret_sha256 = iap.value.oauth2_client_secret_sha256
    }
  }

  depends_on = [
    google_compute_region_health_check.health_check
  ]
}


