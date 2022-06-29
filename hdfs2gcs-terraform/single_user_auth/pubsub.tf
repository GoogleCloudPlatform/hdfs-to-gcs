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

 // This file creates a pubsub topic and a subscrption pull .

resource "google_pubsub_topic" "default" {
  name = "hdfs-gcs-failures"

}
resource "google_pubsub_subscription" "default" {
  name  = "hdfs-gcs-failures-sub"
  topic = google_pubsub_topic.default.name

  retain_acked_messages      = true
  ack_deadline_seconds = 60
  enable_message_ordering    = false
  enable_exactly_once_delivery = true
}