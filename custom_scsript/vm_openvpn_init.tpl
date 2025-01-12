#!/bin/bash

# Update packages and install 
sudo apt update
sudo apt install -y python3 python3-pip python3-venv openvpn easy-rsa

sudo bash -c 'make-cadir ~/openvpn-ca'

sudo bash -c 'tee -a ~/openvpn-ca/vars > /dev/null <<EOF
set_var EASYRSA_REQ_COUNTRY    "UA"
set_var EASYRSA_REQ_PROVINCE   "Kharkiv"
set_var EASYRSA_REQ_CITY       "Kharkiv"
set_var EASYRSA_REQ_ORG        "OKS"
set_var EASYRSA_REQ_EMAIL      "admin@template.com"
set_var EASYRSA_REQ_OU         "IT Department"
EOF'


sudo bash -c 'cd ~/ && ~/openvpn-ca/easyrsa init-pki'

sudo bash -c "cd ~/ && EASYRSA_BATCH=1 EASYRSA_REQ_CN=${vpn_server_url} ~/openvpn-ca/easyrsa build-ca nopass"
sudo bash -c 'cd ~/ && ~/openvpn-ca/easyrsa build-server-full server nopass'
sudo bash -c 'cd ~/ && ~/openvpn-ca/easyrsa gen-dh'


sudo bash -c 'cd ~/ && cp ~/pki/ca.crt /etc/openvpn/'
sudo bash -c 'cd ~/ && cp ~/pki/issued/server.crt /etc/openvpn/'
sudo bash -c 'cd ~/ && cp ~/pki/private/server.key /etc/openvpn/'
sudo bash -c 'cd ~/ && cp ~/pki/dh.pem /etc/openvpn/'

sudo bash -c 'tee /etc/openvpn/server.conf > /dev/null <<EOF
port 1194
proto udp
dev tun
link-mtu 1570
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
cipher AES-256-CBC
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status.log
log-append openvpn.log
comp-lzo
verb 3
EOF'

sudo bash -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'
sudo sysctl -p


sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
sudo bash -c 'iptables-save > /etc/iptables.rules'
#sudo echo "iptables-restore < /etc/iptables.rules" >> /etc/rc.local



sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server


sudo bash -c " cat > ~/createuservpn.sh <<EOF
#!/bin/bash
SERVER_IP=${vpn_server_public_ip}  # Replace with your servers IP address or domain name
EOF"

sudo bash -c ' cat >> ~/createuservpn.sh <<EOF

# Ensure the script is run as root
if [[ \$EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if a username was provided
if [[ -z "\$1" ]]; then
    echo "Usage: \$0 <username>"
    exit 1
fi

USERNAME=\$1
EASYRSA_DIR="/root/openvpn-ca"  # Path to the EasyRSA directory
PKI_DIR="/root/pki"
OUTPUT_DIR="/root/client-configs"  # Directory to store client configuration files
PORT=1194  # OpenVPN server port
PROTOCOL="udp"  # Protocol used by OpenVPN (udp/tcp)

# Create the output directory if it doesnt exist
mkdir -p \$OUTPUT_DIR

# Generate client certificate and key
/\$EASYRSA_DIR/easyrsa build-client-full \$USERNAME nopass

# Check if the certificate generation was successful
if [[ \$? -ne 0 ]]; then
    echo "Error while generating certificate for user \$USERNAME"
    exit 1
fi

# Generate the client .ovpn configuration file
CLIENT_CONFIG="\$OUTPUT_DIR/\$USERNAME.ovpn"

cat > \$CLIENT_CONFIG <<ENDCONFIG
client
dev tun
proto \$PROTOCOL
remote \$SERVER_IP \$PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
auth SHA256
comp-lzo
verb 3

<ca>
\$(cat \$PKI_DIR/ca.crt)
</ca>
<cert>
\$(cat \$PKI_DIR/issued/\$USERNAME.crt)
</cert>
<key>
\$(cat \$PKI_DIR/private/\$USERNAME.key)
</key>
ENDCONFIG

# Output success message
echo "Client configuration file created: \$CLIENT_CONFIG"
EOF'

sudo chmod +x ~/createuservpn.sh 