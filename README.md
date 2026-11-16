## Architecture Diagram

![AWS Terraform Ansible Nginx Architecture](./architecture.png)

## Architecture Workflow

1. **GitHub** – Source code management and version control.
2. **Terraform** – Infrastructure as Code (IaC) to provision and manage AWS infrastructure.
3. **Amazon EC2** – Ubuntu-based virtual machine hosting the application and web server.
4. **Ansible** – Configuration management and automation for installing and configuring Nginx.
5. **Nginx** – Web server responsible for serving web content and handling HTTP requests.
6. **Amazon CloudWatch** – Monitoring AWS resources through metrics, logs, dashboards, and alarms.

## Technologies Used

- **Cloud Platform:** AWS
- **Infrastructure as Code:** Terraform
- **Configuration Management:** Ansible
- **Operating System:** Ubuntu Linux
- **Web Server:** Nginx
- **Monitoring:** Amazon CloudWatch
- **Version Control:** Git and GitHub

## Project Overview

This project demonstrates the automation of AWS infrastructure provisioning and web server configuration using Terraform and Ansible.

Terraform provisions the required AWS infrastructure, including an EC2 instance running Ubuntu. Ansible automates the installation and configuration of Nginx on the EC2 instance. Nginx serves web content, while Amazon CloudWatch provides monitoring through metrics, logs, and alarms.

The project demonstrates practical knowledge of Infrastructure as Code, configuration management, cloud infrastructure deployment, Linux administration, and monitoring.

## Key Learning Outcomes

- Automated AWS infrastructure provisioning using Terraform.
- Configured AWS EC2 instances with Ubuntu.
- Used Ansible playbooks for automated software installation and configuration.
- Installed and configured the Nginx web server.
- Integrated Amazon CloudWatch for infrastructure monitoring.
- Managed project source code using Git and GitHub.
