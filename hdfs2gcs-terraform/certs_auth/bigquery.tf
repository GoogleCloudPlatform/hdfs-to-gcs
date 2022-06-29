/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

 // This file creates a bigquery dataset and 3 underlying tables.

// bq dataset nifi_dataset
resource "google_bigquery_dataset" "default" {
  dataset_id                  = "nifi_dataset"
  location                    = "US"

}

// bq table hdfs_gcp_success
resource "google_bigquery_table" "hdfs_gcp_success" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = "hdfs_gcp_success"
  schema = <<EOF
  [
    {
      "name": "path",
      "type": "STRING",
      "mode": "NULLABLE",
      "description": "path to hdfs file"
    },
    {
      "name": "filename",
      "type": "STRING",
      "mode": "NULLABLE",
      "description": "hdfs file name"
    },
    {
      "name": "filesize",
      "type": "INT64",
      "mode": "NULLABLE",
      "description": "hdfs filesize in bytes"
    },
    {
      "name": "timemillis",
      "type": "INT64",
      "mode": "NULLABLE",
      "description": "timestamp in millis"
    },
    {
      "name": "gcs_filesize",
      "type": "INT64",
      "mode": "NULLABLE",
      "description": "gcs file size"
    },
    {
      "name": "hdfs_crc32c",
      "type": "STRING",
      "mode": "NULLABLE",
      "description": "composite crc32c checksum of file in hdfs"
    },
    {
      "name": "gcs_crc32c",
      "type": "STRING",
      "mode": "NULLABLE",
      "description": "crc32c checksum of file after putting in gcs bucket"
    },
    {
      "name": "hdfs_lastmodified",
      "type": "INT64",
      "mode": "NULLABLE",
      "description": "last modified time of file in HDFS in millis"
    }
  
  ]
  EOF

}
// bq table hdfs_gcp_failures
resource "google_bigquery_table" "hdfs_gcp_failures" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = "hdfs_gcp_failures"
  schema = <<EOF
  [
    {
      "name": "path",
      "type": "STRING",
      "mode": "NULLABLE",
      "description": "path to hdfs file"
    },
    {
      "name": "filename",
      "type": "STRING",
      "mode": "NULLABLE",
      "description": "hdfs file name"
    },
    {
      "name": "nbr_of_retries",
      "type": "INT64",
      "mode": "NULLABLE",
      "description": "number of retries"
    },
    {
      "name": "errmsg",
      "type": "STRING",
      "mode": "NULLABLE",
      "description": "error message"
    },
    {
      "name": "timemillis",
      "type": "INT64",
      "mode": "NULLABLE",
      "description": "timestamp in millis"
    }
    
  ]
EOF

}

// bq table hdfs_gcp_transfer_rate
resource "google_bigquery_table" "hdfs_gcp_transfer_rate" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = "hdfs_gcp_transfer_rate"

  schema = <<EOF
[
  {
    "name": "operation",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "defines fetch hdfs or put gcs operation"
  },
  {
    "name": "filecount",
    "type": "INT64",
    "mode": "NULLABLE",
    "description": "number of files fetched or transferred during the elapsed time"
  },
  {
    "name": "volbytes",
    "type": "INT64",
    "mode": "NULLABLE",
    "description": "volume of data fetched or transfered during elapsed time"
  },
  {
    "name": "timemillis",
    "type": "INT64",
    "mode": "NULLABLE",
    "description": "time in millis"
  }
  
]
EOF

}






