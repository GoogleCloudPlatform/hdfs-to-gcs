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
    }

    metadata_startup_script =   <<EOF
        if [[ ! -f /opt/startup-script-finished.txt ]]
        then 
            if [[ "${var.image}" == *"centos"* ]]; then
            gsutil cp  ${var.nifi-bucket}/binaries/unzip*.rpm /opt
            yum install  /opt/unzip*.rpm -y
            else 
            gsutil cp  ${var.nifi-bucket}/binaries/unzip*.deb /opt
            apt-get install /opt/unzip*.deb -y
            fi
                
            NIFI_UID=10000
            NIFI_GID=10000

            groupadd -g $${NIFI_GID} nifi || groupmod -n nifi `getent group $${NIFI_GID} | cut -d: -f1` \
                && useradd --shell /bin/bash -u $${NIFI_UID} -g $${NIFI_GID} -m nifi \
                && mkdir -p ${var.nifi-path} \
                
            mkdir -p /usr/lib/jvm/tmp-jdk
            gsutil -m cp -r  ${var.nifi-bucket}/binaries/${var.jdkpackage} /usr/lib/jvm/
            cd /usr/lib/jvm/ && tar -xzvf ${var.jdkpackage} -C /usr/lib/jvm/
            rm -f /usr/lib/jvm/${var.jdkpackage}
            cp -R /usr/lib/jvm/jdk*/* /usr/lib/jvm/tmp-jdk && rm -R -f /usr/lib/jvm/jdk* && mv /usr/lib/jvm/tmp-jdk /usr/lib/jvm/jdk 
            chmod -R a+x  /usr/lib/jvm/
            chown -R nifi:nifi /usr/lib/jvm/
            echo "export JAVA_HOME=/usr/lib/jvm/jdk" >> ~/.bashrc
            echo "export PATH=$PATH:/usr/lib/jvm/jdk/bin" >> ~/.bashrc
            gsutil cp ${var.nifi-bucket}/binaries/nifi-toolkit-${var.nifi-version}-bin.zip ${var.nifi-path}
            unzip ${var.nifi-path}/nifi-toolkit-${var.nifi-version}-bin.zip -d ${var.nifi-path}
            rm ${var.nifi-path}/nifi-toolkit-${var.nifi-version}-bin.zip
            chown nifi:nifi -R ${var.nifi-path}/*
            find ${var.nifi-path} -type f -iname "*.sh" -exec chmod +x {} \;
            su nifi -c 'export PATH=$PATH:/usr/lib/jvm/jdk/bin && cd /home/nifi && ${var.nifi-path}/nifi-toolkit-${var.nifi-version}/bin/tls-toolkit.sh server -c ${var.nifi-ca-hostname} -t ${var.ca-token} &'
            sleep 2
            cd /root
            export PATH=$PATH:/usr/lib/jvm/jdk/bin && ${var.nifi-path}/nifi-toolkit-${var.nifi-version}/bin/tls-toolkit.sh client -D CN=${var.bh-hostname},OU=NIFI -c ${var.nifi-ca-hostname} -t ${var.ca-token}
            KEYSTORE_PASSWORD=`cat config.json | grep -o '"keyStorePassword" : "[^"]*' | grep -o '[^"]*$'`
            KEY_PASSWORD=`cat config.json | grep -o '"keyPassword" : "[^"]*' | grep -o '[^"]*$'`
            export PATH=$PATH:/usr/lib/jvm/jdk/bin && keytool -importkeystore -srckeystore keystore.jks -destkeystore keystore.p12 -srcstoretype jks -deststoretype pkcs12 -deststorepass $KEYSTORE_PASSWORD -srcstorepass $KEYSTORE_PASSWORD

            gsutil cp keystore.p12  ${var.nifi-bucket}/bastionhost/
            gsutil cp config.json ${var.nifi-bucket}/bastionhost/
            rm nifi-cert.pem truststore.jks keystore.jks keystore.p12 config.json
            touch /opt/startup-script-finished.txt && echo "the startup script run once" > /opt/startup-script-finished.txt
        fi
        

    EOF
}
