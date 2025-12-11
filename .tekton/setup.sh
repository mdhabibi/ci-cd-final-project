#!/bin/bash
# Setup script for OpenShift CD Pipeline

echo "=========================================="
echo "Setting up OpenShift CD Pipeline"
echo "=========================================="

# Get current namespace
NAMESPACE=$(oc project -q)
echo "Current namespace: $NAMESPACE"

# Step 1: Install Tekton Tasks
echo ""
echo "Step 1: Installing Tekton Tasks..."
kubectl apply -f .tekton/tasks.yml

if [ $? -eq 0 ]; then
    echo "✓ Tasks installed successfully"
else
    echo "✗ Failed to install tasks"
    exit 1
fi

# Step 2: Check if PVC exists
echo ""
echo "Step 2: Checking for PVC..."
oc get pvc oc-lab-pvc -n $NAMESPACE > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "⚠ PVC 'oc-lab-pvc' not found. Please create it in the OpenShift console:"
    echo "   - Name: oc-lab-pvc"
    echo "   - StorageClass: skills-network-learner"
    echo "   - Size: 1GB"
    echo ""
    read -p "Press Enter after creating the PVC to continue..."
fi

# Step 3: Install Pipeline
echo ""
echo "Step 3: Installing Pipeline..."
kubectl apply -f .tekton/pipeline.yml

if [ $? -eq 0 ]; then
    echo "✓ Pipeline installed successfully"
else
    echo "✗ Failed to install pipeline"
    exit 1
fi

# Step 4: Update PipelineRun with correct namespace
echo ""
echo "Step 4: Creating PipelineRun..."
# Update the build-image with the actual namespace
sed "s/\$(context.pipelineRun.namespace)/$NAMESPACE/g" .tekton/pipelinerun.yml > .tekton/pipelinerun-temp.yml
kubectl apply -f .tekton/pipelinerun-temp.yml
rm -f .tekton/pipelinerun-temp.yml

if [ $? -eq 0 ]; then
    echo "✓ PipelineRun created successfully"
    echo ""
    echo "To view the pipeline run:"
    echo "  oc get pipelinerun"
    echo "  tkn pipelinerun logs ci-cd-pipeline-run -f"
else
    echo "✗ Failed to create PipelineRun"
    exit 1
fi

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="

