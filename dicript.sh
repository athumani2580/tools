#!/data/data/com.termux/files/usr/bin/bash
# VPN Configuration Manager - LEGITIMATE USE ONLY

echo "VPN Configuration Manager"
echo "========================="
echo "1) View saved configurations"
echo "2) Import configuration from file"
echo "3) Export configuration"
echo "4) Test connection"
echo "5) Generate WireGuard config"
echo "6) Generate OpenVPN config"

read -p "Select option: " choice

case $choice in
    1)
        echo "Your configurations:"
        ls -la ~/.config/vpn/ 2>/dev/null || echo "No configurations found"
        ;;
    2)
        read -p "Enter config file path: " config_file
        if [ -f "$config_file" ]; then
            cp "$config_file" ~/.config/vpn/
            echo "Configuration imported"
        else
            echo "File not found"
        fi
        ;;
    3)
        echo "Select config to export:"
        ls ~/.config/vpn/ 2>/dev/null
        read -p "Config name: " config_name
        if [ -f ~/.config/vpn/"$config_name" ]; then
            cp ~/.config/vpn/"$config_name" /sdcard/
            echo "Exported to /sdcard/$config_name"
        fi
        ;;
    4)
        echo "Testing connectivity..."
        curl -s ifconfig.me
        echo
        ;;
    5)
        # Generate WireGuard config template
        cat > /sdcard/wg0.conf.template << EOF
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
Endpoint = server.com:51820
AllowedIPs = 0.0.0.0/0
EOF
        echo "WireGuard template created at /sdcard/wg0.conf.template"
        ;;
    6)
        # Generate OpenVPN config template
        cat > /sdcard/client.ovpn.template << EOF
client
dev tun
proto udp
remote YOUR_SERVER_ADDRESS 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
EOF
        echo "OpenVPN template created at /sdcard/client.ovpn.template"
        ;;
    *)
        echo "Invalid option"
        ;;
esac
