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

 // This file creates Windows bastion host VM in which NIFI UI is accessable. 

resource "google_compute_instance" "nifi-bastionhost" {
  name         = "nifi-bastionhost"
  machine_type = "n2-standard-2"
  zone         = var.zone
  project      = var.project-id
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "windows-server-2022-dc-v20220215"
    }
  }
  tags = ["bastionhost"]
  service_account {
        scopes = ["storage-ro"]
    }
  network_interface {
  
    network            = google_compute_network.default.name
    subnetwork         = google_compute_subnetwork.default.name
    access_config { 
  
    } 
  }

}
