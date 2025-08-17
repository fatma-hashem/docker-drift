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
## Usage
./dockerdrift.sh scan <container_name> [--format json]

## Installation 
Clone the repo and make the script executable:
```bash
git clone https://github.com/<your-username>/docker-drift.git
cd docker-drift
chmod +x dockerdrift.sh


