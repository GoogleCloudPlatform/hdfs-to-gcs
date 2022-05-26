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

 // This file creates resources required for NIFI Certificate Authority (CA) server

// Creating NIFI CA VM instance
resource "google_compute_instance" "nifi-ca" {
    name         = var.nifi-ca-hostname
    machine_type = var.nifi-ca-machine-type
    allow_stopping_for_update = true
    tags = ["nifi-ca"]

    service_account {
        scopes = ["cloud-platform"]
    }
    
    boot_disk {
        initialize_params {
            image = var.image
        }
    }

    network_interface {
        network            = google_compute_network.default.name
        subnetwork         = google_compute_subnetwork.default.name
        access_config { 
    }
    }

    metadata_startup_script =   <<EOF
        if [[ ! -f /opt/startup-script-finished.txt ]]
        then
            if [[ "${var.image}" == *"centos"* ]]; then
                yum install     java-11-openjdk-devel unzip -y
            else 
                apt-get update && apt-get -yq install    openjdk-11-jdk unzip 
            fi
                    
            NIFI_UID=10000
            NIFI_GID=10000

            groupadd -g $${NIFI_GID} nifi || groupmod -n nifi `getent group $${NIFI_GID} | cut -d: -f1` \
                && useradd --shell /bin/bash -u $${NIFI_UID} -g $${NIFI_GID} -m nifi \
                && mkdir -p ${var.nifi-path} \
            
            chown nifi:nifi ${var.nifi-path}/
            su nifi -c 'curl -fSL https://archive.apache.org/dist/nifi/${var.nifi-version}/nifi-toolkit-${var.nifi-version}-bin.zip -o ${var.nifi-path}/nifi-toolkit-${var.nifi-version}-bin.zip'
            su nifi -c 'unzip ${var.nifi-path}/nifi-toolkit-${var.nifi-version}-bin.zip -d ${var.nifi-path}'
            su nifi -c 'rm ${var.nifi-path}/nifi-toolkit-${var.nifi-version}-bin.zip'
            touch /opt/startup-script-finished.txt && echo "the startup script run once" > /opt/startup-script-finished.txt
        fi
        su nifi -c 'cd /home/nifi && ${var.nifi-path}/nifi-toolkit-${var.nifi-version}/bin/tls-toolkit.sh server -c ${var.nifi-ca-hostname} -t ${var.ca-token} &'
        sleep 10
        cd /root
        ${var.nifi-path}/nifi-toolkit-${var.nifi-version}/bin/tls-toolkit.sh client -D CN=${var.bh-hostname},OU=NIFI -c ${var.nifi-ca-hostname} -t ${var.ca-token}
        KEYSTORE_PASSWORD=`cat config.json | grep -o '"keyStorePassword" : "[^"]*' | grep -o '[^"]*$'`
        KEY_PASSWORD=`cat config.json | grep -o '"keyPassword" : "[^"]*' | grep -o '[^"]*$'`
        keytool -importkeystore -srckeystore keystore.jks -destkeystore keystore.p12 -srcstoretype jks -deststoretype pkcs12 -deststorepass $KEYSTORE_PASSWORD -srcstorepass $KEYSTORE_PASSWORD

        gsutil cp keystore.p12  ${var.nifi-bucket}/bastionhost/
        gsutil cp config.json ${var.nifi-bucket}/bastionhost/
        rm nifi-cert.pem truststore.jks keystore.jks keystore.p12  config.json
     
    EOF
}