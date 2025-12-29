#!/data/data/com.termux/files/usr/bin/bash

# Colors for Termux
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# Functions
print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║               Termux MTU Tester Script               ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check if running in Termux
    if [ ! -d "/data/data/com.termux" ]; then
        print_error "This script is designed for Termux only!"
        exit 1
    fi
    
    # Update packages
    print_info "Updating package list..."
    pkg update -y > /dev/null 2>&1
    
    # Install required packages
    local missing_pkgs=""
    
    if ! command -v ip &> /dev/null; then
        missing_pkgs+=" iproute2"
    fi
    
    if ! command -v ping &> /dev/null; then
        missing_pkgs+=" iputils-ping"
    fi
    
    if ! command -v tracepath &> /dev/null; then
        missing_pkgs+=" iputils-tracepath"
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_pkgs+=" curl"
    fi
    
    if ! command -v python &> /dev/null; then
        missing_pkgs+=" python"
    fi
    
    if [ ! -z "$missing_pkgs" ]; then
        print_warning "Installing missing packages:$missing_pkgs"
        pkg install -y $missing_pkgs > /dev/null 2>&1
        print_success "Packages installed"
    else
        print_success "All dependencies satisfied"
    fi
}

show_menu() {
    clear
    print_header
    
    echo -e "${YELLOW}Select MTU Test Mode:${NC}"
    echo ""
    echo -e "  ${GREEN}1${NC}. Quick MTU Scan (Auto-detect)"
    echo -e "  ${GREEN}2${NC}. Detailed MTU Analysis"
    echo -e "  ${GREEN}3${NC}. Manual MTU Testing"
    echo -e "  ${GREEN}4${NC}. Network Interface Info"
    echo -e "  ${GREEN}5${NC}. Test Specific Website"
    echo -e "  ${GREEN}6${NC}. Batch MTU Test"
    echo -e "  ${GREEN}7${NC}. Generate MTU Report"
    echo -e "  ${GREEN}8${NC}. About MTU Grades"
    echo -e "  ${GREEN}0${NC}. Exit"
    echo ""
    echo -e "${CYAN}Enter your choice [0-8]: ${NC}"
}

show_mtu_grades() {
    clear
    print_header
    
    echo -e "${YELLOW}📊 MTU Grades Explained:${NC}"
    echo ""
    echo -e "${GREEN}Grade 1: Conservative (1200-1300 bytes)${NC}"
    echo "  • For: Satellite, 3G/4G, unstable connections"
    echo "  • Reliability: ★★★★★"
    echo "  • Speed: ★★☆☆☆"
    echo ""
    echo -e "${GREEN}Grade 2: Standard (1300-1420 bytes)${NC}"
    echo "  • For: Most home broadband, VPNs"
    echo "  • Reliability: ★★★★☆"
    echo "  • Speed: ★★★☆☆"
    echo ""
    echo -e "${GREEN}Grade 3: Optimized (1420-1500 bytes)${NC}"
    echo "  • For: Fiber, stable connections"
    echo "  • Reliability: ★★★☆☆"
    echo "  • Speed: ★★★★☆"
    echo ""
    echo -e "${GREEN}Grade 4: Maximum (1500+ bytes)${NC}"
    echo "  • For: LAN, datacenters, local networks"
    echo "  • Reliability: ★★☆☆☆"
    echo "  • Speed: ★★★★★"
    echo ""
    
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

check_current_mtu() {
    print_info "Checking current MTU settings..."
    echo ""
    
    # Get all network interfaces
    echo -e "${YELLOW}Network Interfaces:${NC}"
    echo "┌──────────────────────┬────────┬────────────────────────────┐"
    echo "│ Interface            │ MTU    │ Status                     │"
    echo "├──────────────────────┼────────┼────────────────────────────┤"
    
    ip -o link show | while read line; do
        iface=$(echo $line | awk '{print $2}' | sed 's/://')
        mtu=$(echo $line | grep -o 'mtu [0-9]*' | awk '{print $2}')
        state=$(echo $line | grep -o 'state [A-Z]*' | awk '{print $2}')
        
        if [ ! -z "$mtu" ]; then
            if [ "$state" = "UP" ]; then
                status="${GREEN}UP${NC}"
            else
                status="${RED}DOWN${NC}"
            fi
            
            printf "│ %-20s │ %-6s │ %-26s │\n" "$iface" "$mtu" "$status"
        fi
    done
    
    echo "└──────────────────────┴────────┴────────────────────────────┘"
    echo ""
}

quick_mtu_scan() {
    clear
    print_header
    echo -e "${YELLOW}🚀 Quick MTU Scan${NC}"
    echo ""
    
    # First check current interface MTU
    check_current_mtu
    
    # Test different MTU sizes
    print_info "Testing optimal MTU to google.com..."
    echo ""
    
    # Test different sizes
    sizes=(1472 1460 1450 1440 1420 1400 1380 1360 1340 1320 1300 1280)
    
    echo -e "${YELLOW}Testing MTU sizes:${NC}"
    echo "┌──────────┬────────────┬─────────────────────┐"
    echo "│ MTU Size │ Fragments? │ Recommended For     │"
    echo "├──────────┼────────────┼─────────────────────┤"
    
    optimal_mtu=0
    for size in "${sizes[@]}"; do
        # Calculate actual packet size
        packet_size=$size
        actual_mtu=$((size + 28))
        
        # Run ping test
        result=$(timeout 3 ping -M do -s $size -c 2 google.com 2>&1)
        
        if echo "$result" | grep -q "Frag needed"; then
            status="${RED}YES${NC}"
            rec="Too High"
        elif echo "$result" | grep -q "1 received"; then
            status="${GREEN}NO${NC}"
            
            # Determine recommendation
            if [ $actual_mtu -ge 1400 ]; then
                rec="Grade 3 (Optimized)"
                [ $optimal_mtu -eq 0 ] && optimal_mtu=$actual_mtu
            elif [ $actual_mtu -ge 1300 ]; then
                rec="Grade 2 (Standard)"
                [ $optimal_mtu -eq 0 ] && optimal_mtu=$actual_mtu
            else
                rec="Grade 1 (Conservative)"
                [ $optimal_mtu -eq 0 ] && optimal_mtu=$actual_mtu
            fi
        else
            status="${YELLOW}TIMEOUT${NC}"
            rec="Unknown"
        fi
        
        printf "│ %-8s │ %-10s │ %-19s │\n" "$actual_mtu" "$status" "$rec"
        
        # Small delay between tests
        sleep 0.5
    done
    
    echo "└──────────┴────────────┴─────────────────────┘"
    echo ""
    
    if [ $optimal_mtu -gt 0 ]; then
        print_success "Recommended MTU: $optimal_mtu bytes"
        
        # Show what this MTU means
        echo ""
        echo -e "${YELLOW}What this means:${NC}"
        if [ $optimal_mtu -ge 1400 ]; then
            echo "• Your connection can handle large packets"
            echo "• Suitable for: Streaming, downloads, VPN"
            echo "• Grade: 3 (Optimized)"
        elif [ $optimal_mtu -ge 1300 ]; then
            echo "• Your connection is average"
            echo "• Suitable for: General browsing, VoIP"
            echo "• Grade: 2 (Standard)"
        else
            echo "• Your connection has limitations"
            echo "• Suitable for: Basic browsing, email"
            echo "• Grade: 1 (Conservative)"
        fi
    else
        print_error "Could not determine optimal MTU"
    fi
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

detailed_mtu_analysis() {
    clear
    print_header
    echo -e "${YELLOW}🔍 Detailed MTU Analysis${NC}"
    echo ""
    
    # Get public IP
    print_info "Getting public IP information..."
    public_ip=$(curl -s ifconfig.me)
    if [ ! -z "$public_ip" ]; then
        echo -e "Public IP: $public_ip"
    fi
    
    # Run traceroute to see path
    print_info "Analyzing network path..."
    echo ""
    
    # Use tracepath
    if command -v tracepath &> /dev/null; then
        tracepath_output=$(timeout 10 tracepath google.com 2>&1 | head -20)
        echo -e "${YELLOW}Network Path Analysis:${NC}"
        echo "$tracepath_output"
    fi
    
    # Test multiple endpoints
    echo ""
    print_info "Testing MTU to multiple endpoints..."
    
    endpoints=("google.com" "cloudflare.com" "1.1.1.1" "8.8.8.8")
    
    for endpoint in "${endpoints[@]}"; do
        echo ""
        echo -e "${BLUE}Testing: $endpoint${NC}"
        
        # Binary search for MTU
        low=500
        high=1500
        best=0
        
        while [ $low -le $high ]; do
            mid=$(( (low + high) / 2 ))
            test_size=$((mid - 28))
            
            if [ $test_size -lt 0 ]; then
                break
            fi
            
            result=$(timeout 2 ping -M do -s $test_size -c 1 $endpoint 2>&1)
            
            if echo "$result" | grep -q "1 received"; then
                best=$mid
                low=$((mid + 1))
            else
                high=$((mid - 1))
            fi
        done
        
        if [ $best -gt 0 ]; then
            echo -e "  ${GREEN}✓${NC} Max MTU: $best bytes"
        else
            echo -e "  ${RED}✗${NC} Could not determine"
        fi
    done
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

manual_mtu_test() {
    clear
    print_header
    echo -e "${YELLOW}🔧 Manual MTU Testing${NC}"
    echo ""
    
    # Get target from user
    echo -e "${CYAN}Enter target (default: google.com): ${NC}"
    read target
    target=${target:-google.com}
    
    # Get MTU size from user
    echo -e "${CYAN}Enter MTU size to test (default: 1500): ${NC}"
    read mtu_size
    mtu_size=${mtu_size:-1500}
    
    # Calculate ping size
    ping_size=$((mtu_size - 28))
    
    if [ $ping_size -lt 0 ]; then
        print_error "MTU too small (must be ≥ 28 bytes)"
        return
    fi
    
    echo ""
    print_info "Testing $target with MTU $mtu_size (ping size: $ping_size)..."
    echo ""
    
    # Run the test
    echo -e "${YELLOW}Test Command:${NC}"
    echo "ping -M do -s $ping_size -c 4 $target"
    echo ""
    
    echo -e "${YELLOW}Results:${NC}"
    ping -M do -s $ping_size -c 4 $target
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

batch_mtu_test() {
    clear
    print_header
    echo -e "${YELLOW}📊 Batch MTU Test${NC}"
    echo ""
    
    # Test multiple MTU sizes
    sizes=(576 1024 1280 1400 1472 1500 1600)
    
    echo -e "${YELLOW}Batch Testing Multiple MTU Sizes:${NC}"
    echo "┌──────────┬────────────┬────────────┬────────────┐"
    echo "│ MTU Size │ Packet Loss │ Avg Latency │ Status    │"
    echo "├──────────┼────────────┼────────────┼────────────┤"
    
    for size in "${sizes[@]}"; do
        ping_size=$((size - 28))
        
        if [ $ping_size -lt 0 ]; then
            continue
        fi
        
        # Run ping test
        result=$(timeout 4 ping -M do -s $ping_size -c 3 google.com 2>&1)
        
        # Extract metrics
        if echo "$result" | grep -q "Frag needed"; then
            loss="100%"
            latency="N/A"
            status="${RED}FRAG${NC}"
        else
            # Parse ping results
            received=$(echo "$result" | grep -o '[0-9]* received' | awk '{print $1}')
            sent=3
            loss=$((100 - (received * 100 / sent)))
            
            latency=$(echo "$result" | grep -o 'min/avg/max/[^=]*' | cut -d'/' -f4 | cut -d' ' -f1)
            if [ -z "$latency" ]; then
                latency="N/A"
            fi
            
            if [ $received -eq 3 ]; then
                status="${GREEN}OK${NC}"
            elif [ $received -ge 1 ]; then
                status="${YELLOW}PARTIAL${NC}"
            else
                status="${RED}FAIL${NC}"
            fi
        fi
        
        printf "│ %-8s │ %-10s │ %-10s │ %-10s │\n" "$size" "$loss%" "$latency" "$status"
    done
    
    echo "└──────────┴────────────┴────────────┴────────────┘"
    echo ""
    
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

generate_mtu_report() {
    clear
    print_header
    echo -e "${YELLOW}📄 Generate MTU Report${NC}"
    echo ""
    
    # Create report file
    report_file="/sdcard/mtu_report_$(date +%Y%m%d_%H%M%S).txt"
    
    print_info "Generating report to: $report_file"
    echo ""
    
    {
        echo "MTU Analysis Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""
        
        echo "1. Network Interfaces:"
        ip -o link show
        echo ""
        
        echo "2. Current Routing Table:"
        ip route show
        echo ""
        
        echo "3. MTU Test Results:"
        
        # Test common MTU sizes
        test_sizes=(576 1024 1280 1400 1472 1500)
        
        for size in "${test_sizes[@]}"; do
            ping_size=$((size - 28))
            
            if [ $ping_size -lt 0 ]; then
                continue
            fi
            
            echo "Testing MTU: $size bytes"
            echo "Command: ping -M do -s $ping_size -c 2 google.com"
            
            result=$(timeout 3 ping -M do -s $ping_size -c 2 google.com 2>&1)
            echo "Result: $result"
            echo ""
        done
        
        echo "4. Recommended Settings:"
        echo "   - For mobile data: 1300-1400 bytes"
        echo "   - For WiFi: 1400-1500 bytes"
        echo "   - For VPN: 1400 bytes"
        echo ""
        
        echo "5. Network Information:"
        echo "   Public IP: $(curl -s ifconfig.me)"
        echo "   DNS Servers: $(cat /etc/resolv.conf 2>/dev/null | grep nameserver)"
        
    } > "$report_file"
    
    print_success "Report generated successfully!"
    echo ""
    echo -e "${CYAN}Report saved to: $report_file${NC}"
    echo ""
    
    # Show quick preview
    echo -e "${YELLOW}Report Preview:${NC}"
    head -20 "$report_file"
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

test_specific_website() {
    clear
    print_header
    echo -e "${YELLOW}🌐 Test Specific Website${NC}"
    echo ""
    
    # Get website from user
    echo -e "${CYAN}Enter website URL (e.g., google.com): ${NC}"
    read website
    
    if [ -z "$website" ]; then
        print_error "Website cannot be empty!"
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read
        return
    fi
    
    # First test connectivity
    print_info "Testing connectivity to $website..."
    if ! ping -c 1 $website &> /dev/null; then
        print_error "Cannot reach $website"
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read
        return
    fi
    
    print_success "Website is reachable"
    echo ""
    
    # Test different MTU sizes
    echo -e "${YELLOW}Testing MTU for $website:${NC}"
    echo ""
    
    sizes=(1280 1300 1350 1400 1450 1472)
    
    for size in "${sizes[@]}"; do
        ping_size=$((size - 28))
        
        echo -ne "Testing MTU $size bytes... "
        
        result=$(timeout 3 ping -M do -s $ping_size -c 2 $website 2>&1)
        
        if echo "$result" | grep -q "Frag needed"; then
            echo -e "${RED}Too Large${NC}"
        elif echo "$result" | grep -q "1 received"; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${YELLOW}Timeout${NC}"
        fi
        
        sleep 0.5
    done
    
    echo ""
    print_info "Additional tests:"
    
    # Test with curl (TCP)
    echo -ne "Testing TCP connection... "
    if timeout 5 curl -s -I "https://$website" &> /dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}May need lower MTU${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

main() {
    # Check dependencies
    check_dependencies
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                quick_mtu_scan
                ;;
            2)
                detailed_mtu_analysis
                ;;
            3)
                manual_mtu_test
                ;;
            4)
                clear
                print_header
                check_current_mtu
                echo -e "${CYAN}Press Enter to continue...${NC}"
                read
                ;;
            5)
                test_specific_website
                ;;
            6)
                batch_mtu_test
                ;;
            7)
                generate_mtu_report
                ;;
            8)
                show_mtu_grades
                ;;
            0)
                clear
                echo -e "${GREEN}Thank you for using Termux MTU Tester!${NC}"
                echo ""
                exit 0
                ;;
            *)
                print_error "Invalid choice! Please try again."
                sleep 2
                ;;
        esac
    done
}

# Run main function
main
