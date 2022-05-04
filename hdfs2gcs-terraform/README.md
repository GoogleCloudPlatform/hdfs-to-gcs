Below scripts provision required resources for Hdfs to GCS solution on GCP. Use these instruction only when you can not have external IP and Internet access on the VMs.
- provider.tf: Specifies "google" as the cloud environment, the project and region where the solution is deployed and the path for service account credential file. 
- nifi.tf: provisioning a cluster of Ubuntu based GCP compute instances with NIFI installed and launched.
- nifi-ca.tf: provisioning a Certitficate Authority server which certifies NIFI cluster instances and bastion host machine
- zookeeper.tf: provisioning a Zookeeper cluster for NIFI cluster coordination.
- network.tf: provisioning a VPC network and subnet resource on GCP wihtin a single region.
- firewall.tf: provisioning control access and trafic rules to and from compute instances
- variable.tf: Contains all the required parameters for the terraform deployment 


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
   
4. Ensure to modify the default values in variable.tf for parameters "ca-token", "sensitivepropskey" , "cert-password". Note that the default region and zone in variable.tf is "us-west1" and "us-west1-a". You may want to modify them to deploy in another area available within GCP. You also can change other default values such as machine-type, instance number, IPs and hostname for cluster instances.
   
5. In case of using an exisiting network, remove the network.tf and firewall.tf scripts from the repositoriy and modify the "network_interface" block in nifi.tf, nifi-ca.tf and zookeeper.tf scripts to include your existing network and subnetwork name. 

6. Run the run.sh script with the GCS bucket name as the input arguments. It may take time for the binaries to be downloaded and pushed to GCS bucket.
```                                              
bash ./run.sh  "bucket_name"
```
7. Once the terraform finished provisioning the required resources, in order to access the NIFI UI, you can provision a Windows VM in the same VPC of the NIFI cluster (set the hostname of this VM to the defualt value of the bh-hostname variable in variable.tf or modify the default value of this parameter before running the run.sh scrip) following [this instruction](https://cloud.google.com/compute/docs/instances/connecting-to-windows) or alternatively provision a Linux VM (with the default hostname) and follow [this intruction](https://cloud.google.com/architecture/chrome-desktop-remote-on-compute-engine) to set up Chrome Remote Desktop.
   
8. Connect to the bastion host VM and follow below steps to open NIFI web interface.
   
9.  Open a terminal and run 
```
gsutil cp gs://${bucket_name}/bastionhost/keystore.p12  gs://${bucket_name}/bastionhost/config.json .

``` 
10. The NIFI CA server has transfererd keystore.p12 and config.json associated to SSL authentication for bastion host to your gcs bucket. The above command downloads the files in your Windows VM. Use them to modify your browser setting. For Microsoft Edge:
 - Open Microsoft Edge browser and select setting-> Privacy, search, and services -> Manage certificates.
 - In the personal tab from the certificate window, select import and browse for downloaded keystore.p12 file.
 - It will ask you to provide the password for the keystore. Copy and paste the value for  "keyStorePassword"  key from the config.json file. 
 - Relaunch the browser and type https://nifi-1:8443/nifi in the URL section to open up the NIFI user interface.  
 - The UI will be preloaded with the flow to transfer files from hdfs to gcs. 
