#!/bin/bash

# Azure Custom Metrics Test Case - Retrieve Metrics
# Usage: ./retrieve-custom-metrics.sh <resource-group> <vm-name>

set -e

RESOURCE_GROUP=${1:-""}
VM_NAME=${2:-""}

if [ -z "$RESOURCE_GROUP" ] || [ -z "$VM_NAME" ]; then
    echo "Usage: $0 <resource-group> <vm-name>"
    echo "Example: $0 rg-azure-metrics-lab vm-dns-monitor-dev"
    exit 1
fi

echo "Retrieving custom metrics from Azure Monitor..."

# Get the VM resource ID
VM_RESOURCE_ID=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query id --output tsv)

if [ -z "$VM_RESOURCE_ID" ]; then
    echo "Error: Could not find VM '$VM_NAME' in resource group '$RESOURCE_GROUP'"
    exit 1
fi

echo "VM Resource ID: $VM_RESOURCE_ID"
echo

# Extract subscription ID from VM resource ID
SUBSCRIPTION_ID=$(echo "$VM_RESOURCE_ID" | cut -d'/' -f3)

# Time range for queries
START_TIME=$(date -u -v-4H +%Y-%m-%dT%H:%M:%SZ)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "=== Querying Custom DNS Metrics via REST API ==="
echo "Time range: $START_TIME to $END_TIME"
echo

# Query both metrics at once using REST API
echo "=== DNS Custom Metrics Data ==="
az rest --method GET \
    --url "https://management.azure.com$VM_RESOURCE_ID/providers/microsoft.insights/metrics?api-version=2018-01-01&metricnames=DNS_Query_Duration,DNS_Query_Success&metricNamespace=Custom/DNS&timespan=$START_TIME/$END_TIME&interval=PT1M&aggregation=Average" \
    --output json | jq -r '
    .value[] | 
    "=== " + .name.value + " ===" + "\n" +
    "Namespace: " + .namespace + "\n" +
    "Time series count: " + (.timeseries | length | tostring) + "\n" +
    (if .timeseries[0].data then
        "Data points with values: " + ([.timeseries[0].data[] | select(has("average"))] | length | tostring) + "\n" +
        "Latest values: " + ([.timeseries[0].data[] | select(has("average"))][-5:] | map("Time: " + .timeStamp + " | Value: " + (.average | tostring)) | join("\n  ")) + "\n"
    else 
        "No data points found\n"
    end) + "\n"
    '

echo
echo "=== Summary Table ==="
az rest --method GET \
    --url "https://management.azure.com$VM_RESOURCE_ID/providers/microsoft.insights/metrics?api-version=2018-01-01&metricnames=DNS_Query_Duration,DNS_Query_Success&metricNamespace=Custom/DNS&timespan=$START_TIME/$END_TIME&interval=PT1M&aggregation=Average" \
    --output json | jq -r '
    ["Metric", "Data Points", "Latest Value", "Time"] as $header |
    ($header | @tsv) + "\n" +
    (.value[] | 
        [
            .name.value,
            ([.timeseries[0].data[] | select(has("average"))] | length | tostring),
            (if .timeseries[0].data then ([.timeseries[0].data[] | select(has("average"))][-1].average | tostring) else "No data" end),
            (if .timeseries[0].data then ([.timeseries[0].data[] | select(has("average"))][-1].timeStamp) else "N/A" end)
        ] | @tsv
    )
    ' | column -t

echo
echo "=== Troubleshooting Info ==="
echo "If no custom metrics are showing:"
echo "1. Check if the DNS monitor script is running on the VM"
echo "2. Verify the VM has managed identity permissions"
echo "3. Check VM logs: /var/log/dns-monitor.log"
echo "4. Custom metrics may take 5-15 minutes to appear in Azure Monitor"

echo "Custom metrics retrieval completed!"