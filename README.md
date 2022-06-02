# HDFS to GCS (HDFS2GCS)  
A complete end to end solution to migrate data from traditional Hadoop clusters to Google Cloud Storage while providing a managed, fault tolerant, seamless experience. Solution is configurable/ customizable and has support for tracking, error handling, throttling, security, validation and monitoring.

## Features
- Support for large data transfers from HDFS to GCS
- Support for incremental/delta loads
- Fault tolerance
- Rate Throttling
- Checksum validation
- Checkpointing/Restartability
- Horizontal scalability
- Zero Coding effort
- Security using IAM, Kerberos, SSL
- Tracking and reporting of data transfer
- Support for Push & Pull model
- Highly configurable

## Supported Distributions
The full solution, including the use of crc32c checksums for transfer validation, is tested with Apache Hadoop 2.10 onwards, which corresponds to Hortonworks 3+ and Cloudera Data Hub 5+. However, the solution supports the transfer of data from earlier distributions of Hadoop without support for crc32c checksum.

## Prerequisites
1. GCP Service account with following permission to deploy the tool for Pull Mode
	- Service account user role to use service compute role
	- ComputeAdmin role to create and manage GCE VMs for tool deployment
2. GCP Service account with following permissions to run flows using HDFS2GCS tool:
	- BigQuery Admin role to insert data for status reporting and failures
	- PubSub Editor role to store and retry failures
	- Storage Admin role to create GCS buckets and objects
3. Account having access to DataStudio for dashboarding
4. Firewall rules/ports to open connectivity between on-prem cluster and GCE VMs
5. Access to hadoop cluster to list and fetch files present in HDFS
	- core-site.xml
	- hdfs-site.xml
	- Kerberos credentials
6. BigQuery dataset with three following tables
    ### Table name: hdfs_gcp_success
    ### Schema:
    | Field name        | Type    | Description                                         |
    |-------------------|---------|-----------------------------------------------------|
    | path              | STRING  | path to hdfs file                                   |
    | filename          | STRING  | hdfs file name                                      |
    | filesize          | INTEGER | hdfs filesize in bytes                              |
    | timemillis        | INTEGER | timestamp in millis                                 |
    | gcs_filesize      | INTEGER | gcs file size                                       |
    | hdfs_crc32c       | STRING  | composite crc32c checksum of file in hdfs           |
    | gcs_crc32c        | STRING  | crc32c checksum of file after putting in gcs bucket |
    | hdfs_lastmodified | INTEGER | last modified time of file in HDFS in millis        |

    ### Table name: hdfs_gcp_failures
    ### Schema:
    | Field name     | Type    | Description         |
    |----------------|---------|---------------------|
    | path           | STRING  | path to hdfs file   |
    | filename       | STRING  | hdfs file name      |
    | nbr_of_retries | INTEGER | number of retries   |
    | errmsg         | STRING  | error message       |
    | timemillis     | INTEGER | timestamp in millis |

    ### Table name: hdfs_gcp_transfer_rate
    ### Schema:

    | Field name | Type    | Description                                                    |
    |------------|---------|----------------------------------------------------------------|
    | operation  | STRING  | defines fetch hdfs or put gcs operation                        |
    | filecount  | INTEGER | number of files fetched or transferred during the elapsed time |
    | volbytes   | INTEGER | volume of data fetched or transfered during elapsed time       |
    | timemillis | INTEGER | time in millis                                                 |

7. PubSub topic for handling failures
8. PubSub Subscription so that tool can replay failures.

## Deployment 
[Follow this guide for the deployment](./hdfs2gcs-terraform/README.md)


## Setup Hdfs to GCS transfer process
Once you lunch the NIFI web UI, modify below parameters and controller services.

## Parameters

| Parameter Name           | Description                                                                                  |
|--------------------------|----------------------------------------------------------------------------------------------|
| bq_dataset               | BigQuery data set name which contains tables for status and transfer reporting               |
| bq_failure_status_table  | BigQuery table name which stores metadata about the files which are failed during transfer   |
| bq_success_status_table  | BigQuery table name which stores metadata about the files which are transferred successfully |
| bq_transfer_rate_table   | BigQuery table name which stores data about transfer rate                                    |
| core-site                | Path to the hadoop core-site.xml file present on the NiFi nodes in the cluster               |
| gcp_project_id           | GCP project id where resources are deployed(GCE, GCS, BigQuery, PubSub)                      |
| hdfs-site                | Path to the hadoop hdfs-site.xml file present on the NiFi nodes in the cluster               |
| kerberos_keytab          | Path to kerberos keytab present on the NiFi nodes                                            |
| kerberos_principal       | Kerberos principal name to connect securely to hadoop cluster                                |
| nifi_api_uri             | NiFi api url                                                                                 |
| pub_sub_topic_name       | PubSub topic name to hold failed files metadata                                              |
| pub_sub_topic_sub        | PubSub topic subscription name to replay failures                                            |

## Controller Services

- GCPCredentialsControllerService : Set the path to service account credential file to access GCP resources (GCS, BigQuery, PubSub) in the flow.
- StandardRestrictedSSLContextService : Provide keystore/truststore settings to call NiFi rest api with secure SSL mechanism.
