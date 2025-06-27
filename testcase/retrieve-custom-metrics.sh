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

# List all available custom metrics
echo "=== Available Custom Metrics ==="
az monitor metrics list-definitions \
    --resource "$VM_RESOURCE_ID" \
    --namespace "Custom/DNS" \
    --query "[].{Name:name.value, Unit:unit, Dimensions:dimensions[].value}" \
    --output table

echo
echo "=== DNS Response Time (Last 1 Hour) ==="
az monitor metrics list \
    --resource "$VM_RESOURCE_ID" \
    --metric "Custom/DNS/ResponseTime" \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --interval PT1M \
    --aggregation Average \
    --query "value[0].timeseries[0].data[?average != null].{Time:timeStamp, Value:average}" \
    --output table

echo
echo "=== DNS Success Rate (Last 1 Hour) ==="
az monitor metrics list \
    --resource "$VM_RESOURCE_ID" \
    --metric "Custom/DNS/SuccessRate" \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --interval PT1M \
    --aggregation Average \
    --query "value[0].timeseries[0].data[?average != null].{Time:timeStamp, Value:average}" \
    --output table

echo
echo "=== DNS Query Count (Last 1 Hour) ==="
az monitor metrics list \
    --resource "$VM_RESOURCE_ID" \
    --metric "Custom/DNS/QueryCount" \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --interval PT1M \
    --aggregation Total \
    --query "value[0].timeseries[0].data[?total != null].{Time:timeStamp, Value:total}" \
    --output table

echo
echo "=== Metrics with Dimensions (Response Time by Domain) ==="
az monitor metrics list \
    --resource "$VM_RESOURCE_ID" \
    --metric "Custom/DNS/ResponseTime" \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --interval PT1M \
    --aggregation Average \
    --filter "domain eq 'example.com'" \
    --query "value[0].timeseries[0].data[?average != null].{Time:timeStamp, Value:average}" \
    --output table

echo "Custom metrics retrieval completed!"