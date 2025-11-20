#!/usr/bin/env python3
"""
PrintALaPi Configuration Web Server
Simple Flask application for basic Raspberry Pi configuration
"""

from flask import Flask, render_template_string, request, jsonify
import subprocess
import os

app = Flask(__name__)

# HTML template for the configuration page
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PrintALaPi Configuration</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }
        .section {
            margin: 20px 0;
            padding: 15px;
            background-color: #f9f9f9;
            border-radius: 5px;
        }
        .status-item {
            display: flex;
            justify-content: space-between;
            padding: 10px;
            border-bottom: 1px solid #ddd;
        }
        .status-item:last-child {
            border-bottom: none;
        }
        .button {
            background-color: #4CAF50;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        .button:hover {
            background-color: #45a049;
        }
        .info {
            color: #666;
            font-size: 14px;
        }
        a {
            color: #4CAF50;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🖨️ PrintALaPi Configuration</h1>
        
        <div class="section">
            <h2>System Status</h2>
            <div class="status-item">
                <span>Hostname:</span>
                <strong>{{ hostname }}</strong>
            </div>
            <div class="status-item">
                <span>IP Address:</span>
                <strong>{{ ip_address }}</strong>
            </div>
            <div class="status-item">
                <span>CUPS Status:</span>
                <strong>{{ cups_status }}</strong>
            </div>
            <div class="status-item">
                <span>SNMP Status:</span>
                <strong>{{ snmp_status }}</strong>
            </div>
        </div>

        <div class="section">
            <h2>Quick Links</h2>
            <p><a href="http://{{ ip_address }}:631" target="_blank">🖨️ CUPS Web Interface</a> - Manage printers</p>
            <p><a href="#" onclick="location.reload()">🔄 Refresh Status</a></p>
        </div>

        <div class="section">
            <h2>Printer Information</h2>
            <div class="info">
                <p><strong>Total Printers:</strong> {{ printer_count }}</p>
                <pre>{{ printer_status }}</pre>
            </div>
        </div>

        <div class="section">
            <h2>Network Information</h2>
            <div class="info">
                <p><strong>Access Point:</strong> {{ ap_status }}</p>
                <p><strong>Wireless Interface:</strong> {{ wireless_if }}</p>
                <p><strong>SSID:</strong> PrintALaPi-Setup</p>
                <p><strong>Password:</strong> printalapy</p>
            </div>
        </div>

        <div class="section">
            <h2>System Actions</h2>
            <button class="button" onclick="rebootSystem()">🔄 Reboot System</button>
        </div>
    </div>

    <script>
        function rebootSystem() {
            if (confirm('Are you sure you want to reboot the system?')) {
                fetch('/reboot', { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        alert(data.message);
                    });
            }
        }
    </script>
</body>
</html>
"""

def run_command(cmd):
    """Execute a shell command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout.strip()
    except Exception as e:
        return f"Error: {str(e)}"

def get_system_status():
    """Gather system status information"""
    status = {}
    
    # Get hostname
    status['hostname'] = run_command('hostname')
    
    # Get IP address
    ip_addr = run_command("hostname -I | awk '{print $1}'")
    status['ip_address'] = ip_addr if ip_addr else 'Unknown'
    
    # Check CUPS status
    cups_check = run_command('systemctl is-active cups')
    status['cups_status'] = '✅ Running' if cups_check == 'active' else '❌ Stopped'
    
    # Check SNMP status
    snmp_check = run_command('systemctl is-active snmpd')
    status['snmp_status'] = '✅ Running' if snmp_check == 'active' else '❌ Stopped'
    
    # Get printer information
    printer_status = run_command('lpstat -p -d 2>/dev/null || echo "No printers configured"')
    status['printer_status'] = printer_status
    status['printer_count'] = len([l for l in printer_status.split('\n') if 'printer' in l])
    
    # Check access point status
    ap_check = run_command('systemctl is-active hostapd')
    status['ap_status'] = '✅ Running' if ap_check == 'active' else '❌ Stopped'
    
    # Get wireless interface
    wireless_if = run_command("ls /sys/class/net | grep -E '^wlan' | head -n1")
    status['wireless_if'] = wireless_if if wireless_if else 'Not found'
    
    return status

@app.route('/')
def index():
    """Main configuration page"""
    status = get_system_status()
    return render_template_string(HTML_TEMPLATE, **status)

@app.route('/reboot', methods=['POST'])
def reboot():
    """Reboot the system"""
    try:
        subprocess.Popen(['sudo', 'reboot'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return jsonify({'message': 'System is rebooting...'})
    except Exception as e:
        return jsonify({'message': f'Error: {str(e)}'}), 500

@app.route('/status')
def status():
    """Return system status as JSON"""
    return jsonify(get_system_status())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
