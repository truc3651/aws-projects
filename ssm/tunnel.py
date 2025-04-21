#!/usr/bin/env python3

import boto3
import json
import subprocess
import os
import sys
import time
from botocore.exceptions import ClientError

class SSMTunnel:
    def __init__(self):
        self.session = boto3.Session()
        self.region = self.session.region_name or 'ap-southeast-1'
        self.ssm = self.session.client('ssm', region_name=self.region)
        self.jumphost_id = self.get_jumphost_id()
        
    def get_jumphost_id(self):
        """Get the jumphost instance ID by tag name."""
        ec2 = self.session.client('ec2', region_name=self.region)
        print(f"🔍 Looking for jumphost instance in region: {self.region}")
        try:
            response = ec2.describe_instances(
                Filters=[
                    {
                        'Name': 'tag:Name',
                        'Values': ['Ssm-JumpHost']
                    },
                    {
                        'Name': 'instance-state-name',
                        'Values': ['running']
                    }
                ]
            )
            
            # Get the first matching instance
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    return instance['InstanceId']
                    
            print("❌ No running jumphost instance found!")
            sys.exit(1)
        except Exception as e:
            print(f"❌ Error finding jumphost: {str(e)}")
            sys.exit(1)
    
    def list_backend_instances(self):
        """List all backend instances to connect to."""
        ec2 = self.session.client('ec2', region_name=self.region)
        try:
            response = ec2.describe_instances(
                Filters=[
                    {
                        'Name': 'tag:Name',
                        'Values': ['Backend-App']
                    },
                    {
                        'Name': 'instance-state-name',
                        'Values': ['running']
                    }
                ]
            )
            
            backends = []
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    backends.append({
                        'instance_id': instance['InstanceId'],
                        'private_ip': instance['PrivateIpAddress']
                    })
            
            return backends
        except Exception as e:
            print(f"❌ Error listing backend instances: {str(e)}")
            return []

    def start_port_forwarding(self, remote_host, remote_port, local_port):
        """Start port forwarding via SSM Session Manager."""
        if not remote_host:
            print("❌ Invalid host. Cannot start SSM session.")
            return
        
        print(f"🔄 Starting port forwarding to {remote_host}:{remote_port} via local port {local_port}")
        
        try:
            response = self.ssm.start_session(
                Target=self.jumphost_id,
                DocumentName="AWS-StartPortForwardingSessionToRemoteHost",
                Parameters={
                    "host": [remote_host],
                    "portNumber": [str(remote_port)],
                    "localPortNumber": [str(local_port)]
                }
            )
            
            # Extract session details
            session_id = response["SessionId"]
            print(f"✅ Started SSM session: {session_id}")
            
            # Run session-manager-plugin
            self.run_session_manager_plugin(response)
            
        except ClientError as e:
            print(f"❌ Error starting SSM session: {str(e)}")
            if "AccessDeniedException" in str(e):
                print("Make sure you have the necessary IAM permissions for SSM.")
    
    def run_session_manager_plugin(self, response):
        """Start and manage the session-manager-plugin process."""
        session_command = [
            "session-manager-plugin",
            json.dumps(response),
            self.region,
            "StartSession",
            "",
            json.dumps({"Target": self.jumphost_id}),
            f"https://ssm.{self.region}.amazonaws.com",
        ]
        
        try:
            # Run session-manager-plugin in foreground
            process = subprocess.Popen(
                session_command,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            
            print("📡 Session established. Press Ctrl+C to terminate.")
            
            try:
                # Keep the session alive
                while process.poll() is None:
                    time.sleep(300)  # Send a keep-alive every 5 minutes
                    if process.poll() is None:  # Check if process is still running
                        process.stdin.write("\n")
                        process.stdin.flush()
            except KeyboardInterrupt:
                print("🛑 Terminating session...")
                process.terminate()
                
            process.communicate()
            
        except Exception as e:
            print(f"❌ Failed to start session-manager-plugin: {str(e)}")
            print("Make sure the AWS Session Manager Plugin is installed.")
            sys.exit(1)
    
    def start_interactive_menu(self):
        """Display an interactive menu for port forwarding options."""
        backends = self.list_backend_instances()
        
        if not backends:
            print("❌ No backend instances found.")
            sys.exit(1)
        
        print("\n==================================")
        print("       SSM Tunnel Manager")
        print("==================================")
        print(f"🖥️  Jumphost: {self.jumphost_id}")
        print("\nAvailable backend instances:")
        
        try:
            selected = backends[0]
            local_port = input("Enter local port to use (default: 3000): ") or "3000"
            
            # Start port forwarding to the Node.js application
            self.start_port_forwarding(
                remote_host=selected['private_ip'],
                remote_port=3000,  # Node.js app port
                local_port=int(local_port)
            )
            
        except KeyboardInterrupt:
            print("\n👋 Exiting...")
            sys.exit(0)
        except ValueError:
            print("❌ Please enter a valid number.")
            sys.exit(1)

if __name__ == "__main__":
    print("🚀 Starting SSM Tunnel Manager")
    
    # Check if session-manager-plugin is installed
    try:
        subprocess.run(["session-manager-plugin"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except FileNotFoundError:
        print("❌ AWS Session Manager Plugin not found!")
        print("Please follow the installation instructions at:")
        print("https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html")
        sys.exit(1)
    
    tunnel = SSMTunnel()
    tunnel.start_interactive_menu()