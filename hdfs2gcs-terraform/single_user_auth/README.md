# Terraform Setup for HDFS2GCS Solution
Below scripts provision required resources for Hdfs to GCS solution on GCP. Use these instruction only when you can not have external IP and Internet access on the VMs. Note that in this deployment only a single user is authenticated by login with username and password in the UI. This feature supports a minimal amount of attempts for security and is not recommended. 
- provider.tf: specifies "google" as the cloud environment, the project and region where the solution is deployed and the path for service account credential file. 
- nifi.tf: provisioning a cluster of Ubuntu based GCP compute instances with NIFI installed and launched.
- nifi-ca.tf: provisioning a Certitficate Authority server which certifies NIFI cluster instances and bastion host machine
- zookeeper.tf: provisioning a Zookeeper cluster for NIFI cluster coordination.
- network.tf: provisioning a VPC network and subnet resource on GCP wihtin a single region.
- firewall.tf: provisioning control access and trafic rules to and from compute instances
- variable.tf: contains all the required parameters for the terraform deployment 
- bigquery.tf: creating a bigquery dataset and 3 tables in the specified region
- pubsub.tf: creating a pubsub topic and a subscription in pull mode 


In order to deploy this solution, follow the below steps: 
1. Clone this project in your local machine and go to "hdfs2gcs-terraform" folder. We are assuming you have terraform (tested with Terraform v0.13.6) is installed in your local machine or use the google cloud shell which comes with terraform.
```
git clone // URL 
cd hdfs2gcs-terraform
gcloud config set project PROJECT_ID
```
2. Modify the credential variable in provider.tf to the path to your service account credential file (*.json). ([How to create service account credential key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating))
   
   a. In case you can not have the service account credential key, edit provider.tf and remove the line for credential variable. Instead, you have to use your own GCP credential and login with 
   ```
   gcloud auth application-default login
   ``` 
3. Copy your core-site.xml & hdfs-site.xml & *.keytab to your GCS bucket and provide your bucket name where you deploy the solution in the step 5.
   
4. Ensure to modify the default values in variable.tf for parameters "ca-token", "sensitivepropskey" , "cert-password", "username" and "password". Note that the default region and zone in variable.tf is "us-west1" and "us-west1-a". You may want to modify them to deploy in another area available within GCP. You also can change other default values such as machine-type, instance number, IPs and hostname for cluster instances.
   
5. In case of using an exisiting network, remove the network.tf and firewall.tf scripts from the repositoriy and modify the "network_interface" block in nifi.tf, nifi-ca.tf and zookeeper.tf scripts to include your existing network and subnetwork name. Make sure to open port 8443 and enable [Private Google Access](https://cloud.google.com/vpc/docs/configure-private-google-access) on your subnet.

6. Run the run.sh script with the GCS bucket name as the input arguments. It may take time for the binaries to be downloaded and pushed to GCS bucket.
```                                              
bash ./run.sh  "bucket_name"
```
1. Once the terraform finished provisioning the required resources, in order to access the NIFI UI, you can provision a Windows VM in the same VPC of the NIFI cluster or alternatively provision a Linux VM (with the default hostname) and follow [this intruction](https://cloud.google.com/architecture/chrome-desktop-remote-on-compute-engine) to set up Chrome Remote Desktop.
   - You can also use SSH with IAP's TCP forwarding feature wraps an SSH connection inside HTTPS. Learn more from this [link](https://cloud.google.com/iap/docs/using-tcp-forwarding#tunneling_with_ssh).
2. Connect to the bastion host VM and follow below steps to open NIFI web interface.
   
3. Open URL "https://nifi-1:8443/nifi" in a browser and use the username and password values from variable.tf to login.
