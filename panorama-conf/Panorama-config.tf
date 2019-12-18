provider "panos" {
  hostname = var.mgt-ipaddress-rama1
  username = var.username
  password = var.password
}

resource "panos_panorama_template" "template1" {
  //name = "template1"
  name        = var.template_name
  description = "description here"
}
resource "panos_panorama_template_stack" "templatestk" {
  name        = var.template_stack_name
  description = "Template stack via tf"
  templates   = [var.template_name]

}
resource "panos_panorama_device_group" "example" {
  name        = var.device_grp_name
  description = "Device group name via tf"
}

resource "panos_panorama_management_profile" "icmp_allow_ping" {
  template = var.template_name
  name     = "Allow ping"
  ping     = true
}


resource "panos_panorama_ethernet_interface" "eth1_1" {
  name                      = "ethernet1/1"
  template                  = var.template_name
  vsys                      = "vsys1"
  mode                      = "layer3"
  comment                   = "External interface"
  enable_dhcp               = true
  create_dhcp_default_route = true
  management_profile        = panos_panorama_management_profile.icmp_allow_ping.name
}

resource "panos_panorama_ethernet_interface" "eth1_2" {
  name                      = "ethernet1/2"
  template                  = var.template_name
  vsys                      = "vsys1"
  mode                      = "layer3"
  comment                   = "External interface"
  enable_dhcp               = true
  create_dhcp_default_route = false
  management_profile        = panos_panorama_management_profile.icmp_allow_ping.name
}

resource "panos_panorama_zone" "zone_untrust" {
  template   = var.template_name
  name       = "untrust"
  mode       = "layer3"
  interfaces = [panos_panorama_ethernet_interface.eth1_1.name]
}

resource "panos_panorama_zone" "zone_trust" {
  template   = var.template_name
  name       = "trust"
  mode       = "layer3"
  interfaces = [panos_panorama_ethernet_interface.eth1_2.name]
}

resource "panos_panorama_service_object" "so_22" {
  name             = "service-tcp-22"
  protocol         = "tcp"
  destination_port = "22"
}

resource "panos_panorama_service_object" "so_81" {
  name             = "service-http-81"
  protocol         = "tcp"
  destination_port = "81"
}

resource "panos_panorama_address_object" "azure_health" {
  name        = "azure-lb-health-probe"
  value       = "168.63.129.16/32"
  description = "Azure Health Probe"
}

resource "panos_panorama_security_policies" "security_policies" {
  rule {
    name                  = "Allow lb probe from outside"
    source_zones          = [panos_panorama_zone.zone_untrust.name]
    source_addresses      = ["azure-lb-health-probe"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["ssh"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
  }
  rule {
    name                  = "Allow lb probe from inside"
    source_zones          = [panos_panorama_zone.zone_trust.name]
    source_addresses      = ["azure-lb-health-probe"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = ["any"]
    destination_addresses = ["any"]
    applications          = ["ssh"]
    services              = ["application-default"]
    categories            = ["any"]
    action                = "allow"
  }

  rule {
    name                  = "Web browsing"
    source_zones          = [panos_panorama_zone.zone_trust.name]
    source_addresses      = ["any"]
    source_users          = ["any"]
    hip_profiles          = ["any"]
    destination_zones     = [panos_panorama_zone.zone_trust.name, panos_panorama_zone.zone_untrust.name]
    destination_addresses = ["any"]
    applications          = ["web-browsing"]
    services              = ["service-http"]
    categories            = ["any"]
    action                = "allow"
  }
}

resource "panos_panorama_nat_rule_group" "nat1" {
  rule {
    name = "second"
    original_packet {
      source_zones          = [panos_panorama_zone.zone_trust.name]
      destination_zone      = panos_panorama_zone.zone_untrust.name
      destination_interface = "any"
      source_addresses      = ["any"]
      destination_addresses = ["any"]
    }
    translated_packet {
      source {
        dynamic_ip_and_port {
          interface_address {
            interface = panos_panorama_ethernet_interface.eth1_1.name
          }
        }
      }
      destination {
      }
    }
  }

}


resource "panos_panorama_virtual_router" "vr1" {
  template = var.template_name
  name     = "vr1"
  interfaces = [
    panos_panorama_ethernet_interface.eth1_1.name,
  panos_panorama_ethernet_interface.eth1_2.name]
}

resource "panos_panorama_static_route_ipv4" "net10_nets" {
  name           = "10_nets"
  virtual_router = panos_panorama_virtual_router.vr1.name
  template       = var.template_name
  interface      = panos_panorama_ethernet_interface.eth1_2.name
  destination    = "10.0.0.0/8"
  next_hop       = cidrhost(var.trust_cidr, 1)
}

resource "panos_panorama_static_route_ipv4" "net192_nets" {
  name           = "192_nets"
  virtual_router = panos_panorama_virtual_router.vr1.name
  template       = var.template_name
  interface      = panos_panorama_ethernet_interface.eth1_2.name
  destination    = "192.168.0.0/16"
  next_hop       = cidrhost(var.trust_cidr, 1)
}

resource "panos_panorama_static_route_ipv4" "net172_nets" {
  name           = "172_nets"
  virtual_router = panos_panorama_virtual_router.vr1.name
  template       = var.template_name
  interface      = panos_panorama_ethernet_interface.eth1_2.name
  destination    = "172.16.0.0/12"
  next_hop       = cidrhost(var.trust_cidr, 1)
}