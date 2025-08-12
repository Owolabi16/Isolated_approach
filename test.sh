for chart in alaffia fdw reports gpt-search document-api autodor-py file-api graphql; do
  cat > charts/$chart/Chart.yaml << EOF
apiVersion: v2
name: $chart
version: 0.0.0
description: Mock $chart chart for testing
type: application
EOF

  cat > charts/$chart/values.yaml << EOF
# Default values for $chart
replicaCount: 1
EOF
done
