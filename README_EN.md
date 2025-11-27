# 🎯 Kubernetes Deployment Example

> A production-grade login system with complete Kubernetes deployment solution  
> **Tech Stack**: Vue3 + Django + PostgreSQL + Kubernetes

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Vue3](https://img.shields.io/badge/Vue.js-35495E?style=flat&logo=vue.js&logoColor=4FC08D)](https://vuejs.org/)
[![Django](https://img.shields.io/badge/Django-092E20?style=flat&logo=django&logoColor=white)](https://www.djangoproject.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

[中文文档](./README.md) | **English**

---

## ✨ Features

- 🎨 **Modern Frontend**: Vue3 + Vite for rapid development
- 🔐 **Secure Authentication**: JWT Token with Refresh Token support
- 🚀 **High Availability**: Multi-replica deployment with auto health checks
- 💾 **Data Persistence**: PostgreSQL + PersistentVolume
- 📦 **Containerized**: Multi-stage Docker builds with optimized image size
- ☸️ **K8s Native**: Complete Kubernetes deployment configuration
- 🌐 **China Optimized**: Configured with China mirror sources for faster builds

---

## 📸 System Architecture

```
┌─────────────────────────────────────────────────────┐
│          Kubernetes Cluster (Minikube)              │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌────────────┐  Nginx    ┌────────────┐          │
│  │  Frontend  │ ────────→ │  Backend   │          │
│  │  (Vue3)    │  Proxy    │  (Django)  │          │
│  │  2 Pods    │           │  3 Pods    │          │
│  └────────────┘           └──────┬─────┘          │
│       ↑                          │                 │
│       │ HTTP                     │ SQL             │
│  User Access                ┌─────▼─────┐          │
│  :8080                      │PostgreSQL │          │
│                             │  + PV     │          │
│                             └───────────┘          │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### One-Click Deployment (5 minutes)

```bash
# 1. Clone the project
git clone https://github.com/ChengFengGu/SimpleK8sDeploy.git
cd 01-k8s

# 2. Configure Docker environment
eval $(minikube docker-env)

# 3. Build images
docker build -t login-backend:latest ./backend
docker build -t login-frontend:latest ./frontend

# 4. Create storage directory
minikube ssh "sudo mkdir -p /mnt/data/postgres && sudo chmod 777 /mnt/data/postgres"

# 5. Deploy to K8s
./scripts/deploy.sh

# 6. Access the system
kubectl port-forward -n login-system service/frontend-service 8080:80
# Open browser: http://localhost:8080
```

**Detailed deployment steps**: See **[📘 Deployment Guide](./部署指南.md)** (Chinese version)

---

## 📦 Project Structure

```
01-k8s/
├── frontend/                 # Frontend (Vue3)
│   ├── src/
│   │   ├── views/           # Page components (Login, Register, Home)
│   │   ├── router/          # Router configuration
│   │   ├── api/             # API interfaces
│   │   └── utils/           # Utilities (Token management)
│   ├── Dockerfile           # Frontend image (53MB)
│   ├── nginx.conf           # Nginx configuration
│   └── vite.config.js       # Vite configuration
│
├── backend/                  # Backend (Django)
│   ├── apps/
│   │   └── authentication/  # Authentication app
│   │       ├── models.py    # User model
│   │       ├── serializers.py  # Serializers
│   │       └── views.py     # API views
│   ├── config/              # Django configuration
│   ├── Dockerfile           # Backend image (116MB)
│   └── requirements.txt     # Python dependencies
│
├── k8s/                     # Kubernetes configuration
│   ├── namespace.yaml       # Namespace
│   ├── postgres/            # PostgreSQL configuration
│   │   ├── *-secret.yaml
│   │   ├── *-configmap.yaml
│   │   ├── *-pv.yaml
│   │   ├── *-pvc.yaml
│   │   ├── *-deployment.yaml
│   │   └── *-service.yaml
│   ├── backend/             # Backend configuration
│   └── frontend/            # Frontend configuration
│
├── scripts/                 # Deployment scripts
│   ├── install-k8s-cn.sh   # K8s installation (China mirrors)
│   ├── deploy.sh           # One-click deployment
│   ├── cleanup.sh          # Cleanup script
│   ├── backup.sh           # Data backup
│   ├── restore.sh          # Data restore
│   └── setup-windows-access.sh  # Windows access setup
│
└── README.md               # Documentation
```

---

## 🛠️ Tech Stack

### Frontend
| Technology | Version | Description |
|------------|---------|-------------|
| Vue.js | 3.x | Progressive JavaScript framework |
| Vite | 5.x | Next generation frontend tooling |
| Vue Router | 4.x | Official router |
| Axios | 1.x | HTTP client |
| Nginx | Alpine | Web server + reverse proxy |

### Backend
| Technology | Version | Description |
|------------|---------|-------------|
| Django | 4.2 | Python web framework |
| DRF | 3.14 | Django REST Framework |
| JWT | 5.3 | JSON Web Token authentication |
| PostgreSQL | 15 | Relational database |
| Gunicorn | 21.2 | WSGI server |

### DevOps
| Technology | Version | Description |
|------------|---------|-------------|
| Kubernetes | 1.34+ | Container orchestration |
| Docker | 20.10+ | Containerization platform |
| Minikube | latest | Local K8s cluster |

---

## 🎯 Functionality

### ✅ Implemented Features

- [x] User registration (Email validation, password strength check)
- [x] User login (JWT Token authentication)
- [x] Token refresh (Refresh Token support)
- [x] Auto Token injection (Axios interceptor)
- [x] Route guards (Auto redirect when not logged in)
- [x] User profile display
- [x] User logout (Token cleanup)
- [x] Health check endpoint
- [x] Data persistence (PostgreSQL + PV)
- [x] Multi-replica high availability
- [x] Auto health checks and recovery
- [x] Rolling update support

### 🚧 Extensible Features

- [ ] Password recovery (Email)
- [ ] Profile editing
- [ ] Avatar upload
- [ ] Third-party login (OAuth)
- [ ] Multi-factor authentication (MFA)
- [ ] Admin dashboard
- [ ] Audit logs
- [ ] Ingress + domain access
- [ ] HTTPS/TLS support
- [ ] Monitoring (Prometheus + Grafana)

---

## 🌐 API Endpoints

### Public Endpoints (No authentication required)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/register/` | User registration |
| POST | `/api/token/` | User login (Get token) |
| POST | `/api/token/refresh/` | Refresh token |
| GET  | `/api/health/` | Health check |

### Protected Endpoints (Authentication required)

| Method | Path | Description |
|--------|------|-------------|
| GET  | `/api/profile/` | Get user info |
| PUT  | `/api/profile/` | Update user info |
| POST | `/api/logout/` | User logout |

**API Documentation**: After deployment, visit http://localhost:8080/api/ for DRF auto-generated docs

---

## 🔧 Requirements

### Required
- Docker >= 20.10
- Kubernetes (Minikube/K3s/Kind)
- kubectl >= 1.19
- At least 4GB RAM
- At least 10GB disk space

### Optional
- Git
- curl/wget
- Visual Studio Code (Recommended)

---

## 📊 Performance Metrics

| Metric | Value |
|--------|-------|
| **Image Size** | Frontend 53MB, Backend 116MB |
| **Startup Time** | < 60s (including DB migration) |
| **Memory Usage** | ~1.5GB (all Pods) |
| **Concurrency** | 100+ concurrent users |
| **Response Time** | API < 50ms, Page < 200ms |

---

## 🐛 Troubleshooting

### Common Issues

1. **Pod stuck in Pending**: Check PV/PVC binding status
2. **Image pull failed**: Make sure to use `eval $(minikube docker-env)`
3. **Cannot access**: Use `kubectl port-forward` instead of direct Minikube IP
4. **Database connection failed**: Wait for PostgreSQL Pod to be fully ready

For detailed solutions: See [Deployment Guide - FAQ](./部署指南.md#常见问题)

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork this project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 Changelog

### v1.0.0 (2025-11-27)
- ✅ Complete frontend and backend functionality
- ✅ Complete K8s deployment configuration
- ✅ Complete deployment documentation
- ✅ Optimize build speed (China mirror sources)
- ✅ Fix registration endpoint bug
- ✅ Add data backup and restore scripts

---

## 📄 License

This project is for learning and research purposes only.

---

## 🙏 Acknowledgments

- [Kubernetes](https://kubernetes.io/) - Container orchestration platform
- [Vue.js](https://vuejs.org/) - Progressive JavaScript framework
- [Django](https://www.djangoproject.com/) - High-level Python web framework
- [PostgreSQL](https://www.postgresql.org/) - Powerful open-source database

---

## 📞 Contact

- Documentation: See `部署指南.md` (Chinese)
- Technical Details: See `技术文档.md` (Chinese)
- Issue Reporting: Submit an Issue
- Discussion: Create a Discussion

---

<div align="center">

**⭐ If this project helps you, please give it a Star ⭐**

Made with ❤️ by AI Assistant

</div>

