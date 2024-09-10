![alt text](./images/architecture.jpeg)
![alt text](./images/tree.png)

## What this lab requires:

EC2
 - use free AMI comes with Linux OS (ec2-user)
 - launch template
 - security group

ELB

RDS

## Lab 1:
 - teraform apply vpc-ec2
 - Launch 1 more ec2, but this time in different AZ
 - Create target group, includes those 2 EC2 instances
 - Create Load Balancer (default: round robin)
 - Retrieve ALB DNS name and self test

## Lab 2:
 - Create EC2 launch template from your EC2 instance
 - Remove all EC2 from Lab 1
 - Launch EC2 Auto Scaling (min=1, max=2, desired=1)
 - After launched, you can see there's gonna be 1 EC2 (as specify desired=1)

## Lab 3:
 - Create managed policy (cpu 40% threshold)
 - Create IAM role for ALB to access CloudWatch
 - Connect ssh to any EC2, test stress to make it scale out (amazon-stress-utility)
 - Follow ALB monitor screen and CloudWatch red alarm



question
- when scale in / scale out, do I have to register target group again


EC2 Auto Scaling cool features:
 - Instance refresh
 - Lifecycle hooks
 - Scale-in protection
 - Rebalancing events