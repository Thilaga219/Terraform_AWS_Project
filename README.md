# Terraform_AWS_Project
Create infrastructure on AWS using Terraform

```
User Browser
     |
     v
[ Application Load Balancer (ALB) ]
     |
     v
[ Listener (port 80, HTTP) ]
     |
     v
[ Target Group "mytg" ]
     |
     +--> EC2 Instance 1 (web-server-1) (Welcome to Terraform project)
     +--> EC2 Instance 2 (web-server-2) (Welcome to Thilagas learning)
```
<img width="921" height="358" alt="image" src="https://github.com/user-attachments/assets/1042ab55-16e8-479f-a95f-b1126ea27abf" />

<img width="1083" height="427" alt="image" src="https://github.com/user-attachments/assets/4eee06b2-48c8-445e-af4e-e7e04f377968" />
     
# 1. VPC - 
Created a virtual private cloud (VPC), which is an isolated network in AWS where all other resources will reside.

# 2. Public Subnets
Two public subnets were created in different availability zones for high availability.
These subnets allow instances to automatically get public IPs, so they can communicate with the Internet.

# 3. Internet Gateway and Routing
An internet gateway was created to allow resources inside the VPC to access the Internet.
A route table was defined to route all outgoing traffic to the internet gateway.
The route table was associated with both subnets to enable Internet connectivity for instances.

# 4. Security Group
A security group was created to control traffic to instances.
Inbound rules allow HTTP (port 80) and SSH (port 22) from any IP.
Outbound traffic is allowed to all destinations.

# 5. S3 Bucket
An S3 bucket was created to store logs for the ALB.
Ownership controls ensure the bucket owner maintains control over uploaded objects.

# 6. EC2 Instances
Two EC2 instances were created in the two public subnets.
Both instances are connected to the security group to allow HTTP and SSH access.
User data scripts are configured to run on instance startup for setup.

# 7. Application Load Balancer (ALB)
A public ALB was created to distribute incoming HTTP traffic to the EC2 instances.
Both subnets are attached to the ALB to ensure high availability.
ALB access logs were removed temporarily to prevent S3 permission errors.

# 8. Target Group
A target group was created to define where the ALB should send traffic (the two EC2 instances).
Health checks are configured so the ALB only forwards traffic to healthy instances.

# 9. Target Group Attachments
Each EC2 instance is registered with the target group.
This ensures the ALB can forward HTTP traffic to both instances.

# 10. ALB Listener
A listener was created on port 80.
Incoming HTTP requests to the ALB are forwarded to the target group.

# 11. Output
The DNS name of the ALB is output so users can access the application via a web browser.

<img width="424" height="350" alt="image" src="https://github.com/user-attachments/assets/27408c10-9890-4ffe-aa66-329c855c425c" />
<img width="1735" height="751" alt="image" src="https://github.com/user-attachments/assets/ac54af4c-5701-4a3b-99ee-869210a50b0e" />
<img width="1732" height="724" alt="image" src="https://github.com/user-attachments/assets/0b6a0ea0-fe40-4ada-a00d-208782cbf16f" />
<img width="1731" height="742" alt="image" src="https://github.com/user-attachments/assets/14d884ba-788e-4b51-bc49-c36bffc80d4b" />


