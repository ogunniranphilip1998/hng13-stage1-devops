 HNG13 DevOps Stage 1 - Automated Deployment Script

 Author
**Name:** Ogunniran Philip  
**Slack Username:** Radiance 

---

 Project Overview
This project is part of the **HNG13 DevOps Internship (Stage 1)**.  
It automates the deployment of a Dockerized web application onto a remote Linux server using **a single Bash script**.

The script handles:
- Repository cloning from GitHub using a Personal Access Token (PAT)
- Remote environment setup (Docker, Docker Compose, and Nginx installation)
- Docker container deployment and management
- Nginx reverse proxy configuration
- Logging and error handling throughout the process

---

##  Features
 	Fully automated, single-command deployment  
	Handles Docker or Docker Compose projects  
	Secure SSH-based remote setup  
	Configures Nginx reverse proxy automatically  
	Validates deployment health  
	Idempotent — can safely re-run without breaking existing setups  

---

##  Files Included
| File | Description |
|------|--------------|
| `deploy.sh` | Main automation script |
| `README.md` | Documentation file |

---

 Prerequisites
Before running the script, make sure you have:
- A **GitHub repository** containing a valid `Dockerfile` or `docker-compose.yml`
- A **Personal Access Token (PAT)** with repo access  
- A **Linux remote server (e.g., DigitalOcean, AWS EC2, etc.)**
- SSH access to that server (username, IP, and key)
- Bash installed on your local machine

---

## Usage Instructions
### Make the script executable
```bash
chmod +x deploy.sh
