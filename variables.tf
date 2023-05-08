variable "name" {
  description = "The name of the load balancer"
  type        = string
}

variable "project_id" {
  description = "Project id of the load balancer"
  type        = string
}

variable "lb_type" {
  description = "Few options to select the load balancer type"
  type = object({
    is_global = bool
    is_external = bool
    is_proxied  = bool 
  })

  validation {
    condition = (var.lb_type.is_global ? 1 : 0) + (!var.lb_type.is_external ? 1 : 0) <= 1
    error_message = "There is no Global internal L4 Load balancer, Select other one."
  }

  validation {
    condition = (var.lb_type.is_global && var.lb_type.is_external ? 1 : 0) + (!var.lb_type.is_proxied ? 1 : 0) <= 1
    error_message = "There is no Global external L4 Load balancer with non-proxy, Select other one."
  }
}

variable "region" {
  description = "The region of the Internal load balancer. If specified, Create regional load balancer"
  type = string
  default = null
}

variable "network" {
  description = "The URL of the network to which this load balancer belongs"
  type = string
  default = null
}

variable "impersonate_sa" {
  description = "Email of the service account to use for Terraform"
  type        = string
}

variable "validate_labels" {
  description = "validate labels"
  type        = map(string)
}


############################
## Frontend configuration ##
############################

variable "frontend_configs" {
  description = "Frontend configuration of L7 load balancer"
  type = map(object({
    description      = optional(string)
    protocol         = string                   # TCP, UDP, SSL 
    ip_version       = optional(string, "IPV4") # IPV4 , IPV6  External only
    ip_address       = optional(string)         # literal IP address , Existing Address resource (Ephemeral IP is assigned if null)
    port             = optional(object({
      numbers = optional(list(number)) # Non-proxy LB : maximum 5 port numbers available , Proxy LB : Only 1 Port available
      all = optional(bool) # Non-proxy LB only available
    }))
         
    ssl_policy       = optional(string)
    certificate_map  = optional(string)
    enable_proxy_protocol   = optional(bool)
    subnet = optional(string) # Internal only (Not Proxy-only subnet)
    allow_global_access = optional(bool) # Internal only
    service_label = optional(string) # Internal TCP,UDP LB only
    enable_packet_mirroring = optional(bool) # Internal TCP,UDP Non-proxy LB only
    service_directory_registration = optional(object({ # Internal only
      namespace = string
      service = string
    }))

  }))
  default = {}

  validation {
    condition = alltrue([for k,v in var.frontend_configs : v.protocol == "TCP"|| v.protocol == "UDP" || v.protocol == "SSL"])
    #condition     = var.frontend_configs.protocol == "HTTP" || var.frontend_configs.protocol == "HTTPS"
    error_message = "Protocol must be TCP or UDP or SSL"
  }

  validation {
    condition     = alltrue([for k,v in var.frontend_configs : v.port != 443 || v.protocol != "HTTP"])
    error_message = "443 port can only be specified when HTTPS protocol is set"
  }

  validation {
    condition     = alltrue([for k,v in var.frontend_configs : v.port != 80 || v.protocol != "HTTPS"])
    error_message = "80 port can only be specified when HTTP protocol is set"
  }

  validation {
    condition     = alltrue([for k,v in var.frontend_configs : v.port != 8080 || v.protocol != "HTTPS"])
    error_message = "8080 port can only be specified when HTTP protocol is set"
  }

  validation {
    condition = alltrue([for k,v in var.frontend_configs :
    (v.port.numbers != null ? 1 : 0) + (v.port.all != null ? 1 : 0) <= 1 ])
    error_message = "Only one of the numbers or all port options can be specified"
  }
}

variable "frontend_ssl_certs" {
  description = "ssl certificates for existing, custom, managed certificates"
  type = object({
    certificate_ids = optional(list(string), []) # For Existing Cert
    custom_cert = optional(map(object({ # For creating Custom cert
      certificate = string
      private_key = string
      description = optional(string)
    })), {})
    managed_cert = optional(map(object({ # For creating Managed cert
      domains     = list(string)
      description = optional(string)
    })), {})
  })
  default  = {}
  nullable = false
}

###########################
## Backend configuration ##
###########################

variable "backend_services" {
  description = "Backend services configuration of L7 load balancer"
  type = map(object({

    #### General ####

    description  = optional(string)
    backend_type = string # INSTANCE_GROUP , NEG
    protocol     = string # TCP , UDP , SSL
    named_port   = optional(string) # Applicapable only at TCP/SSL Proxy LB
    timeout_sec  = optional(number) # Applicapable only at TCP/SSL Proxy LB
  

    #### Backends ####

    backends = list(object({
      group = string # fully-qualified URL of Instance Group or Network Endpoint Group
      enable_failover = optional(bool) # Applicapable only at TCP/UDP LB
      balancing_mode = object({
        utilization = optional(object({                   # Only one of utilization or connection can be specified
          max_utilization              = optional(number) # 0.0 ~ 1.0
          max_connections              = optional(number) # Only one of max_connections or max_rps can be specified
          max_connections_per_instance = optional(number)
          max_rps_per_group            = optional(number)
          max_rps_per_instance         = optional(number)
        }))
        connection = optional(object({
          max_connections    = optional(number)
          max_connections_per_instance = optional(number)
        }))
        capacity = optional(number, 1) # 0.0 ~ 1.0 
      })
      description = optional(string)
    }))

    #### Health Check ####

    health_check = optional(list(string)) # Currently at most one health check can be specified

    #### Logging ####

    log_config = optional(object({ # Logging option cannot use with Regional TCP/SSL Proxy LB  
      enable      = optional(bool)
      sample_rate = optional(number) # 0.0 ~ 1.0 default is 1.0
    }))

    #### Session Affinity ####

    session_affinity                = optional(string) # NONE(default), CLIENT_IP, CLIENT_IP_PORT_PROTO, CLIENT_IP_PROTO, CLIENT_IP_NO_DESTINATION(Internal Network LB only)
    connection_draining_timeout_sec = optional(number)

    #### Traffic Policy ####

    locality_lb_policy = optional(string) # ROUND_ROBIN , LEAST_REQUEST , RANDOM , ORIGINAL_DESTINATION , MAGLEV  Applicapable only at Internal TCP Proxy LB

    #### Circuit Breaker ####

    circuit_breakers = optional(object({ # Applicable only at Internal TCP Proxy LB
      max_requests_per_connection = optional(number)
      max_connections             = optional(number) # default is 1024
      max_pending_requests        = optional(number) # default is 1024
      max_requests                = optional(number) # default is 1024
      max_retries                 = optional(number) # default is 1
    }))

    #### Outlier Detection ####

    outlier_detection = optional(object({ # Applicable only at Internal TCP Proxy LB
      consecutive_errors = optional(number) # default is 5
      interval = optional(object({
        seconds = number           # 0 ~ 315,576,000,000
        nanos   = optional(number) # 0 ~ 999,999,999 with seconds 0
      }))
      base_ejection_time = optional(object({
        seconds = number           # 0 ~ 315,576,000,000 
        nanos   = optional(number) # 0 ~ 999,999,999 with seconds 0
      }))
      max_ejection_percent                  = optional(number) # default is 50
      success_rate_minimum_hosts            = optional(number) # default is 5
      success_rate_stdev_factor             = optional(number) # default is 1900
      success_rate_request_volume           = optional(number) # default is 100
      enforcing_consecutive_errors          = optional(number) # default is 0
      enforcing_success_rate                = optional(number) # default is 100
      consecutive_gateway_failure           = optional(number) # default is 5
      enforcing_consecutive_gateway_failure = optional(number) # default is 100
    }))

    ### Failover Policy #### 

    failover_policy = optional(object({ # Applicapable only at Non-proxy LB
      disable_connection_drain_on_failover = optional(bool)
      drop_traffic_if_unhealthy = optional(bool)
      failover_ratio = optional(number) # 0 ~ 1
    }))

    #### IAP Configuration ####

    iap_config = optional(object({
      oauth2_client_id            = string
      oauth2_client_secret        = string
      oauth2_client_secret_sha256 = string
    }))
  }))
  default = {}
  validation {
    condition     = alltrue([for k,v in var.backend_services : v.protocol == "TCP" || v.protocol == "UDP" || v.protocol == "SSL"])
    error_message = "Protocol must be TCP or UDP or SSL"
  }
  validation {
    condition     = alltrue([for k,v in var.backend_services : v.session_affinity == "HTTP_COOKIE" || try(v.consistent_hash.http_cookie, null) == null])
    error_message = "http_cookie argument is applicable only if the session_affininity is set to HTTP_COOKIE"
  }
  validation {
    condition     = alltrue([for k,v in var.backend_services : v.session_affinity == "HEADER_FIELD" || try(v.consistent_hash.http_header_name, null) == null])
    error_message = "http_header_name argument is applicable only if the session_affininity is set to HEADER_FIELD"
  }
  validation {
    condition     = alltrue([for k,v in var.backend_services : v.locality_lb_policy == "RING_HASH" || try(v.consistent_hash.minimum_ring_size, null) == null])
    error_message = "minimum_ring_hash argument is applicable only if the localty_lb_policy is set to RING_HASH"
  }
}

################################
## HealthCheck configuration ###
################################

variable "healthcheck_config" {
  description = "Health Check configurations of L7 load balancer to create"
  type = map(object({
    description = optional(string)
    http = optional(object({
      host               = optional(string) # default is null (Public IP of the backend)
      port               = optional(number) # default is 80
      port_name          = optional(string) # InstanceGroup#NamedPort#name , If both port and port_name are defined, port takes precedence
      proxy_header       = optional(string) # NONE(default) , PROXY_V1
      request_path       = optional(string) # default is /
      response           = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT , USE_NAMED_PORT , USE_SERVING_PORT
    }))
    https = optional(object({
      host               = optional(string) # default is null (Public IP of the backend)
      port               = optional(number) # default is 80
      port_name          = optional(string) # InstanceGroup#NamedPort#name , If both port and port_name are defined, port takes precedence
      proxy_header       = optional(string) # NONE(default) , PROXY_V1
      request_path       = optional(string) # default is /
      response           = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT , USE_NAMED_PORT , USE_SERVING_PORT
    }))
    http2 = optional(object({
      host               = optional(string) # default is null (Public IP of the backend)
      port               = optional(number) # default is 80
      port_name          = optional(string) # InstanceGroup#NamedPort#name , If both port and port_name are defined, port takes precedence
      proxy_header       = optional(string) # NONE(default) , PROXY_V1
      request_path       = optional(string) # default is /
      response           = optional(string)
      port_specification = optional(string) # USE_FIXED_PORT , USE_NAMED_PORT , USE_SERVING_PORT
    }))
    enable_log          = optional(bool)   # default is false
    check_interval_sec  = optional(number) # default is 5
    timeout_sec         = optional(number) # default is 5
    healthy_threshold   = optional(number) # default is 2
    unhealthy_threshold = optional(number) # default is 2
  }))
  default = {}

  validation {
    condition     = alltrue([for k,v in var.healthcheck_config : v.timeout_sec <= v.check_interval_sec])
    error_message = "It is invalid for timeoutSec to have greater value than checkIntervalSec"
  }
}





