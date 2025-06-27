#!/bin/bash

# Azure Custom Metrics Test Case - Send Metrics
# Usage: ./send-custom-metrics.sh <resource-group> <vm-name>

set -e

RESOURCE_GROUP=${1:-""}
VM_NAME=${2:-""}

if [ -z "$RESOURCE_GROUP" ] || [ -z "$VM_NAME" ]; then
    echo "Usage: $0 <resource-group> <vm-name>"
    echo "Example: $0 rg-azure-metrics-lab vm-dns-monitor-dev"
    exit 1
fi

echo "Sending custom metrics to Azure Monitor..."

# Get the VM resource ID
VM_RESOURCE_ID=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query id --output tsv)

if [ -z "$VM_RESOURCE_ID" ]; then
    echo "Error: Could not find VM '$VM_NAME' in resource group '$RESOURCE_GROUP'"
    exit 1
fi

echo "VM Resource ID: $VM_RESOURCE_ID"

# Get access token for Azure Monitor
ACCESS_TOKEN=$(az account get-access-token --resource https://monitor.azure.com/ --query accessToken --output tsv)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Could not obtain access token for Azure Monitor"
    exit 1
fi

# Azure region from VM location (assuming West Europe)
REGION="westeurope"

# Azure Monitor Custom Metrics ingestion endpoint
METRICS_ENDPOINT="https://$REGION.monitoring.azure.com$VM_RESOURCE_ID/metrics"

# Current timestamp in ISO 8601 format
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Send DNS response time metric
RESPONSE=$(curl -s -X POST "$METRICS_ENDPOINT" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "time": "'$TIMESTAMP'",
        "data": {
            "baseData": {
                "metric": "ResponseTime",
                "namespace": "Custom/DNS",
                "dimNames": ["domain", "stage", "metric_type"],
                "series": [{
                    "dimValues": ["example.com", "test", "response_time"],
                    "min": 45.2,
                    "max": 45.2,
                    "sum": 45.2,
                    "count": 1
                }]
            }
        }
    }')

if echo "$RESPONSE" | grep -q "AuthorizationFailed"; then
    echo "❌ Error: Authorization failed. You need the 'Monitoring Metrics Publisher' role."
    echo "   Run: az role assignment create --assignee \$(az account show --query user.name -o tsv) --role 'Monitoring Metrics Publisher' --scope '$VM_RESOURCE_ID'"
    exit 1
elif echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Error sending ResponseTime metric:"
    echo "$RESPONSE"
    exit 1
else
    echo "✓ Sent DNS ResponseTime metric: 45.2ms"
fi

# If first metric was successful, send the other metrics
# Send DNS success rate metric  
RESPONSE=$(curl -s -X POST "$METRICS_ENDPOINT" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "time": "'$TIMESTAMP'",
        "data": {
            "baseData": {
                "metric": "SuccessRate",
                "namespace": "Custom/DNS", 
                "dimNames": ["domain", "stage", "metric_type"],
                "series": [{
                    "dimValues": ["example.com", "test", "success_rate"],
                    "min": 98.5,
                    "max": 98.5,
                    "sum": 98.5,
                    "count": 1
                }]
            }
        }
    }')

if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Error sending SuccessRate metric: $RESPONSE"
else
    echo "✓ Sent DNS SuccessRate metric: 98.5%"
fi

# Send query count metric
RESPONSE=$(curl -s -X POST "$METRICS_ENDPOINT" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "time": "'$TIMESTAMP'",
        "data": {
            "baseData": {
                "metric": "QueryCount",
                "namespace": "Custom/DNS",
                "dimNames": ["domain", "stage", "metric_type"],
                "series": [{
                    "dimValues": ["example.com", "test", "query_count"],
                    "min": 1,
                    "max": 1,
                    "sum": 1,
                    "count": 1
                }]
            }
        }
    }')

if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ Error sending QueryCount metric: $RESPONSE"
else
    echo "✓ Sent DNS QueryCount metric: 1"
fi

echo "Custom metrics sent successfully!"
echo "Note: Metrics may take 1-5 minutes to appear in Azure Monitor"