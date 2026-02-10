#!/bin/bash
# DNS Diagnostic Tool for Termux
# Legitimate network troubleshooting only

echo "======================================"
echo "     DNS Configuration Diagnostic"
echo "======================================"

# Check current DNS servers
echo -e "\n[1] CURRENT DNS SERVERS:"
echo "--------------------------------------"
getprop | grep dns || echo "Unable to get DNS from properties"
echo "From /etc/resolv.conf (if exists):"
cat /etc/resolv.conf 2>/dev/null || echo "No resolv.conf found"

# Check for active DNS connections
echo -e "\n[2] ACTIVE DNS CONNECTIONS:"
echo "--------------------------------------"
echo "Port 53 (Traditional DNS/UDP):"
netstat -an 2>/dev/null | grep ":53" | head -5 || echo "No port 53 connections"
echo -e "\nPort 853 (DNS over TLS - DoT):"
netstat -an 2>/dev/null | grep ":853" | head -5 || echo "No port 853 connections"

# Check for browser/App DNS settings
echo -e "\n[3] DETECTED DNS PROTOCOL INDICATORS:"
echo "--------------------------------------"
echo "Checking for common DNS services..."

# Test traditional DNS
echo -e "\nTesting traditional DNS (UDP/TCP 53):"
nslookup google.com 8.8.8.8 2>&1 | grep -A2 "Name:" || echo "Traditional DNS test failed"

# Test if DoT is reachable
echo -e "\nTesting DNS over TLS (DoT) connectivity:"
timeout 3 openssl s_client -connect 8.8.8.8:853 2>/dev/null | grep -i "dns" && echo "DoT endpoint detected" || echo "No DoT response on standard port"

# Check for DoH capabilities
echo -e "\nTesting DNS over HTTPS (DoH) support:"
curl -s -H "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=google.com&type=A" 2>/dev/null | grep -q "Answer" && echo "DoH endpoint responsive" || echo "DoH test inconclusive"

# Show system DNS configuration
echo -e "\n[4] SYSTEM DNS CONFIGURATION:"
echo "--------------------------------------"
echo "Network properties:"
ip route show 2>/dev/null | grep default || echo "Default route not found"

# Security information
echo -e "\n[5] DNS SECURITY INFORMATION:"
echo "--------------------------------------"
echo "Note: Using encrypted DNS (DoH/DoT) can:"
echo "  ✓ Prevent DNS spoofing"
echo "  ✓ Encrypt DNS queries from local observers"
echo "  ✓ Bypass simple DNS-based filtering"
echo ""
echo "Important: Always use DNS services in compliance"
echo "with your network's acceptable use policy."

echo -e "\n======================================"
echo "For legitimate DNS troubleshooting only."
echo "Respect all network policies and terms."
echo "======================================"
