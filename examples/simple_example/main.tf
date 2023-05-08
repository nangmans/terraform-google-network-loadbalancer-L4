
module "network_loadbalancer_L4" {
  source = "../.."
  region = "asia-northeast3"
  lb_type = {
    is_external = false
    is_global = false
    is_proxied = true
  }
  name = "test"
  project_id = "prj-sandbox-devops-9999"
  network = "default"
  frontend_configs = {
    test = {
      description = "test"
      subnet = "default"
      #ip_address = "10.0.0.1"
      #ip_version = "IPV4"
      port = {
        numbers = [80]
        #all = true
      }
      protocol = "TCP"
      #quic_negotiation = "NONE"
    }
  }
  backend_services = {
    backendservice1 = {
      affinity_cookie_ttl_sec = 1
      backend_type = "INSTANCE_GROUP"
      backends = [ {
        balancing_mode = {
          # capacity = 1 # capacity_scaler" cannot be set for non-managed backend service
          connection = {
            max_connections = 1
          }
        }
        description = "test"
        group = "https://www.googleapis.com/compute/v1/projects/prj-sandbox-devops-9999/zones/asia-northeast3-a/instanceGroups/gke-gke-dev-clouddevops-sandbo-pool-1-64276d8a-grp"
      } ] 
      health_check = ["hc-hc1"]
      # log_config = {
      #   enable = false
      #   sample_rate = 1
      # }
      named_port = "http"
      protocol = "TCP"
    }
  }
  healthcheck_config = {
    "hc1" = {
      check_interval_sec = 1
      enable_log = false
      healthy_threshold = 1
      http = {
        host = "test"
        port = 80
        # port_name = "value"
        # port_specification = "value"
        # proxy_header = "value"
        # request_path = "value"
        # response = "value"
      }
      name = "test-hc"
      timeout_sec = 1
      unhealthy_threshold = 1
    }
    "hc2" = {
      check_interval_sec = 1
      enable_log = false
      healthy_threshold = 1
      http = {
        host = "test"
        port = 80
        # port_name = "value"
        # port_specification = "value"
        # proxy_header = "value"
        # request_path = "value"
        # response = "value"
      }
      name = "test-hc"
      timeout_sec = 1
      unhealthy_threshold = 1
    }    
  }
}
