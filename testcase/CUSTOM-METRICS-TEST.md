# Azure Custom Metrics Test Case

This test case demonstrates how to send and retrieve custom metrics using Azure CLI.

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Azure VM deployed (using the Terraform infrastructure in this project)
- Appropriate permissions to send metrics to Azure Monitor

## Test Scripts

### 1. Send Custom Metrics

```bash
./send-custom-metrics.sh <resource-group> <vm-name>
```

**Example:**
```bash
./send-custom-metrics.sh rg-azure-metrics-lab vm-dns-monitor-dev
```

This script sends three types of DNS monitoring metrics:
- `Custom/DNS/ResponseTime` - DNS query response time in milliseconds
- `Custom/DNS/SuccessRate` - Success rate percentage 
- `Custom/DNS/QueryCount` - Number of queries performed

Each metric includes dimensions: `domain`, `stage`, and `metric_type`.

### 2. Retrieve Custom Metrics

```bash
./retrieve-custom-metrics.sh <resource-group> <vm-name>
```

**Example:**
```bash
./retrieve-custom-metrics.sh rg-azure-metrics-lab vm-dns-monitor-dev
```

This script retrieves and displays:
- Available custom metric definitions
- DNS response time data (last hour)
- Success rate data (last hour) 
- Query count data (last hour)
- Filtered metrics by dimension

## Expected Output

### Send Metrics Output:
```
Sending custom metrics to Azure Monitor...
VM Resource ID: /subscriptions/.../resourceGroups/rg-azure-metrics-lab/providers/Microsoft.Compute/virtualMachines/vm-dns-monitor-dev
✓ Sent DNS ResponseTime metric: 45.2ms
✓ Sent DNS SuccessRate metric: 98.5%
✓ Sent DNS QueryCount metric: 1
Custom metrics sent successfully!
Note: Metrics may take 1-5 minutes to appear in Azure Monitor
```

### Retrieve Metrics Output:
```
=== Available Custom Metrics ===
Name           Unit           Dimensions
ResponseTime   Milliseconds   [domain, stage, metric_type]
SuccessRate    Percent        [domain, stage, metric_type]
QueryCount     Count          [domain, stage, metric_type]

=== DNS Response Time (Last 1 Hour) ===
Time                     Value
2024-01-15T10:30:00Z    45.2

=== DNS Success Rate (Last 1 Hour) ===
Time                     Value
2024-01-15T10:30:00Z    98.5
```

## Notes

- Custom metrics may take 1-5 minutes to appear in Azure Monitor after sending
- The VM must exist and be accessible for the scripts to work
- Metrics are stored with a 30-day retention period by default
- You can filter metrics by dimensions using the `--filter` parameter
- Different aggregation types are available: Average, Total, Maximum, Minimum, Count