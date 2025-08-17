# # 🐳 Docker Drift

Detect and report **drift** between running Docker containers and their original images.  
Drift occurs when files, packages, or configurations inside a container are changed without updating the Dockerfile.

---

## Features
-  File system change detection (`docker diff`)
-  Package difference checking (coming soon)
-  Multiple output formats (Markdown / JSON)
-  CI/CD-friendly exit codes for automation

---

## Why Docker Drift?
In DevOps and production environments, containers often **drift** when:
- Packages are manually installed inside running containers  
- Configurations are updated without changing the image  
- Security patches are applied directly in containers  

This leads to:
- ❌ Inconsistent environments  
- ❌ Security vulnerabilities  
- ❌ Hard-to-reproduce bugs  

**Docker Drift helps catch those issues early.**

---

## Installation 
Clone the repo and make the script executable:
```bash
git clone https://github.com/<your-username>/docker-drift.git
cd docker-drift
chmod +x dockerdrift.sh
```
### Step-by-Step Example

1. Start a container to test drift:
```bash
docker run -d --name my-test-container ubuntu sleep 60
#Install a package manually inside the container to simulate drift:
docker exec my-test-container apt-get update
docker exec my-test-container apt-get install -y curl
#Run Docker Drift:
./dockerdrift.sh my-test-container
```
*Docker Drift helps catch those issues early.**

---


## Installation 
Clone the repo and make the script executable:
```bash
git clone https://github.com/<your-username>/docker-drift.git
cd docker-drift
chmod +x dockerdrift.sh
```
### Step-by-Step Example

1. Start a container to test drift:
```bash
docker run -d --name my-test-container ubuntu sleep 60
#Install a package manually inside the container to simulate drift:
docker exec my-test-container apt-get update
docker exec my-test-container apt-get install -y curl
#Run Docker Drift:
./dockerdrift.sh my-test-container
```
```## Example Output:
Scanning container: my-test-container

Filesystem Drift:
C /etc/apt/sources.list
A /usr/bin/curl

Package Drift:
Added:
curl 8.2.1-1ubuntu3
```

### Run in CI/CD

1. Push a change to your repo (or open a pull request).
2. GitHub Actions will automatically run `drift.sh` and report drift in the workflow logs.
3. Example workflow snippet:
```yaml
- name: Run Docker Drift
  run: ./drift.sh my-test-container
```
### Note on Testing Containers

During testing (for example, in the Step-by-Step Example and GitHub Actions), we sometimes compare two running containers instead of a container and its original image.
This is for demonstration purposes: one container simulates the “original” image, while the other is modified to show how drift is detected.
In practice, Docker Drift compares a container to its original image to detect filesystem or package changes.
