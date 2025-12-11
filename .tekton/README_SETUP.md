# OpenShift CD Pipeline Setup Instructions

## Prerequisites
- Access to an OpenShift cluster
- `oc` CLI tool installed and configured
- `kubectl` CLI tool installed
- Tekton Pipelines installed in the cluster

## Step-by-Step Setup

### 1. Install Tekton Tasks
```bash
kubectl apply -f .tekton/tasks.yml
```

Verify tasks are installed:
```bash
kubectl get tasks
```

You should see: `cleanup`, `nose`, and `flake8`

### 2. Create PVC in OpenShift Console

1. Open OpenShift Console
2. Switch to **Administrator** perspective
3. Navigate to **Storage** → **PersistentVolumeClaims**
4. Click **Create PersistentVolumeClaim**
5. Configure:
   - **Name**: `oc-lab-pvc`
   - **StorageClass**: `skills-network-learner`
   - **Size**: `1GB`
   - **Access Mode**: ReadWriteOnce
6. Click **Create**

### 3. Install Pipeline
```bash
kubectl apply -f .tekton/pipeline.yml
```

Verify pipeline is installed:
```bash
kubectl get pipeline
```

### 4. Create and Run PipelineRun

#### Option A: Using the provided PipelineRun file
```bash
# Update the namespace and image name in .tekton/pipelinerun.yml if needed
kubectl apply -f .tekton/pipelinerun.yml
```

#### Option B: Using the setup script
```bash
bash .tekton/setup.sh
```

#### Option C: Create via OpenShift Console
1. Navigate to **Pipelines** → **Pipelines**
2. Select `ci-cd-pipeline`
3. Click **Actions** → **Start**
4. Configure parameters:
   - **app-name**: `counter-app` (or your app name)
   - **build-image**: `image-registry.openshift-image-registry.svc:5000/<namespace>/counter-app:latest`
   - **git-url**: `https://github.com/mdhabibi/ci-cd-final-project.git`
   - **git-revision**: `main`
5. Configure workspace:
   - **output**: Select PVC `oc-lab-pvc`
6. Click **Start**

### 5. Monitor Pipeline Execution

Watch the pipeline run:
```bash
tkn pipelinerun logs ci-cd-pipeline-run -f
```

Or check status:
```bash
oc get pipelinerun
oc describe pipelinerun ci-cd-pipeline-run
```

### 6. Verify Application Deployment

Check if the deployment was created:
```bash
oc get deployments
oc get pods
```

View application logs:
```bash
oc logs -l app=counter-app
```

## Pipeline Steps

The pipeline executes in this order:
1. **cleanup** - Cleans the workspace
2. **git-clone** - Clones the repository
3. **flake8-lint** - Runs linting checks
4. **nose-tests** - Runs unit tests
5. **buildah-build** - Builds the container image
6. **oc-deploy** - Deploys the application to OpenShift

## Troubleshooting

### Pipeline fails at cleanup step
- Check PVC is created and bound: `oc get pvc oc-lab-pvc`

### Pipeline fails at git-clone
- Verify git-url parameter is correct
- Check network connectivity from cluster

### Pipeline fails at buildah
- Verify image registry permissions
- Check if image push is allowed in namespace

### Pipeline fails at oc-deploy
- Verify you have deployment permissions
- Check if the image was built successfully

## Manual PipelineRun Creation

If you need to create a PipelineRun manually:

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: ci-cd-pipeline-run-$(date +%s)
spec:
  pipelineRef:
    name: ci-cd-pipeline
  params:
    - name: app-name
      value: counter-app
    - name: build-image
      value: image-registry.openshift-image-registry.svc:5000/<namespace>/counter-app:latest
    - name: git-url
      value: https://github.com/mdhabibi/ci-cd-final-project.git
    - name: git-revision
      value: main
  workspaces:
    - name: output
      persistentVolumeClaim:
        claimName: oc-lab-pvc
```

Replace `<namespace>` with your actual OpenShift namespace.

