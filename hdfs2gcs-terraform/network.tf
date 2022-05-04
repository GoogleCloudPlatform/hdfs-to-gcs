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
// This file creates VPC network and subnetwork with provided cidr range


// Creating VPC network
resource "google_compute_network" "default" {
  name                    = var.network-name
  auto_create_subnetworks = "false"
}

// Creating VPC subnetwork
resource "google_compute_subnetwork" "default" {
  name                     = "${var.network-name}-subnet"
  ip_cidr_range            = var.network-ip-cidr-range
  network                  = google_compute_network.default.self_link

  region                   = var.region
  private_ip_google_access = true
}
