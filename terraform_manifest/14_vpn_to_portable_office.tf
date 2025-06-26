resource "aws_vpn_gateway" "poc_vgw" {
  count = var.enable_vpn ? 1 : 0

  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-VGW"
  }
}



resource "aws_customer_gateway" "branch_cgw" {
  count      = var.enable_vpn ? 1 : 0
  bgp_asn    = 65000
  ip_address = aws_eip.branch_vpn_eip[0].public_ip
  type       = "ipsec.1"

  tags = {
    Name = "Branch-Office-CGW"
  }
}
resource "aws_vpn_connection" "poc_to_branch" {
  count               = var.enable_vpn ? 1 : 0
  customer_gateway_id = aws_customer_gateway.branch_cgw[0].id
  vpn_gateway_id      = aws_vpn_gateway.poc_vgw[0].id
  type                = "ipsec.1"

  static_routes_only = true

  tags = {
    Name = "POC-to-Branch-VPN"
  }
}

# Define VPN static routes for both sides
resource "aws_vpn_connection_route" "to_branch_vpc" {
  count                  = var.enable_vpn ? 1 : 0
  vpn_connection_id      = aws_vpn_connection.poc_to_branch[0].id
  destination_cidr_block = "12.0.0.0/16"
}
resource "aws_route" "poc_to_branch" {
  count                  = var.enable_vpn ? 1 : 0
  route_table_id         = aws_route_table.private-route-table-main.id
  destination_cidr_block = "12.0.0.0/16"
  gateway_id             = aws_vpn_gateway.poc_vgw[0].id
}
resource "aws_route" "branch_to_poc" {
  count                  = var.enable_vpn ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "11.0.0.0/16"
  gateway_id             = aws_internet_gateway.branch_office.id # Replace with your VPN instance ID if using Openswan/StrongSwan
}

resource "aws_eip" "branch_vpn_eip" {
  count = var.enable_vpn ? 1 : 0

  tags = {
    Name = "Branch-VPN-EIP"
  }
}

resource "aws_security_group" "branch_vpn_sg" {
  count  = var.enable_vpn ? 1 : 0
  name   = "branch-vpn-sg"
  vpc_id = aws_vpc.branch_office.id

  ingress {
    description = "IKEv2"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "IPSec NAT Traversal"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ESP protocol"
    from_port   = 0
    to_port     = 0
    protocol    = "50"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.34.117.5/32"] # replace with your current IP address. Limit for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Branch-VPN-SG"
  }
}
resource "aws_instance" "branch_vpn" {
  count                       = var.enable_vpn ? 1 : 0
  ami                         = "ami-00b7ea845217da02c" # Amazon Linux 2 
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  key_name                    = "POC"
  vpc_security_group_ids      = [aws_security_group.branch_vpn_sg[0].id]
  private_ip                  = "12.0.1.10"

  user_data = <<-EOF
    #!/bin/bash
    yum install -y libreswan
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    cat > /etc/sysctl.conf <<EOL
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
EOL
 sysctl -p
    cat > /etc/ipsec.conf <<EOL
config setup
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12
    protostack=netkey
    nat_traversal=yes
    oe=off
    interfaces=%defaultroute
include /etc/ipsec.d/aws.conf
EOL

    cat > /etc/ipsec.d/aws.conf <<EOL
conn tunnel1
    authby=secret
    auto=start
    type=tunnel
    left=%defaultroute
    leftid=${aws_eip.branch_vpn_eip[0].public_ip}
    leftsubnet=12.0.0.0/16
    right=${aws_vpn_connection.poc_to_branch[0].tunnel1_address}
    rightsubnet=11.0.0.0/16
    ike=aes256-sha1;modp1024
    phase2alg=aes256-sha1
    keyexchange=ike
    ikelifetime=8h
    salifetime=1h
    dpddelay=10
    dpdtimeout=30
    dpdaction=restart

conn tunnel2
    authby=secret
    auto=start
    type=tunnel
    left=%defaultroute
    leftid=${aws_eip.branch_vpn_eip[0].public_ip}
    leftsubnet=12.0.0.0/16
    right=${aws_vpn_connection.poc_to_branch[0].tunnel2_address}
    rightsubnet=11.0.0.0/16
    ike=aes256-sha1;modp1024
    phase2alg=aes256-sha1
    keyexchange=ike
    ikelifetime=8h
    salifetime=1h
    dpddelay=10
    dpdtimeout=30
    dpdaction=restart
EOL

    cat > /etc/ipsec.d/aws.secrets <<EOL
${aws_eip.branch_vpn_eip[0].public_ip} ${aws_vpn_connection.poc_to_branch[0].tunnel1_address} : PSK "${aws_vpn_connection.poc_to_branch[0].tunnel1_preshared_key}"
${aws_eip.branch_vpn_eip[0].public_ip} ${aws_vpn_connection.poc_to_branch[0].tunnel2_address} : PSK "${aws_vpn_connection.poc_to_branch[0].tunnel2_preshared_key}"
EOL

    systemctl enable ipsec
    systemctl restart ipsec
  EOF

  tags = {
    Name = "branch-vpn-instance"
  }
}

resource "aws_eip_association" "vpn_assoc" {
  count         = var.enable_vpn ? 1 : 0
  allocation_id = aws_eip.branch_vpn_eip[0].id
  instance_id   = aws_instance.branch_vpn[0].id
}


output "address-tunnel-2" {
  value     = aws_vpn_connection.poc_to_branch[0].tunnel2_address
  sensitive = false
}