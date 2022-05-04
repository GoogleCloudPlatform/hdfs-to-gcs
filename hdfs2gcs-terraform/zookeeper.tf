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

 // The scripts provisions resources requried for Zookeeper cluster 

// Creating Zookeeper VM instances 
resource "google_compute_instance" "zookeeper" {
    count        = var.instance-count-zk
    name         = "${var.zookeeper-hostname}-${count.index + 1}"
    machine_type = var.zookeeper-machine-type
    zone         = var.zone
    project      = var.project-id
    allow_stopping_for_update = true
    tags = ["zookeeper"]

    service_account {
        scopes = ["storage-ro"]
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
    } // uncomment to generate ephemeral external IP
    }

    metadata_startup_script =   <<EOF

        if [[ "${var.image}" == *"centos"* ]]; then 
            yum install  unzip  java-11-openjdk-devel -y
        else 
            apt-get update && apt-get install   unzip  openjdk-11-jdk -y
        fi
        
        ZOOK_UID=10000
        ZOOK_GID=10000

        groupadd -g $${ZOOK_GID} zookeeper || groupmod -n zookeeper `getent group $${ZOOK_GID} | cut -d: -f1` \
            && useradd --shell /bin/bash -u $${ZOOK_UID} -g $${ZOOK_GID} -m zookeeper \
            && mkdir -p /opt/zookeeper \
            && mkdir -p /var/lib/zookeeper \
            && echo ${count.index + 1} > /var/lib/zookeeper/myid \
            && chown -R zookeeper:zookeeper /opt/zookeeper \
            && chown -R zookeeper:zookeeper /var/lib/zookeeper 
            
        su zookeeper -c 'curl -fSL https://downloads.apache.org/zookeeper/zookeeper-${var.zk-version}/apache-zookeeper-${var.zk-version}-bin.tar.gz -o /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin.tar.gz'
        chown -R zookeeper:zookeeper /opt/zookeeper/
        su zookeeper -c 'cd /opt/zookeeper && tar -xzvf /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin.tar.gz'
        su zookeeper -c 'rm /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin.tar.gz'
        echo "tickTime=2000" > /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/conf/zoo.cfg
        echo "dataDir=/var/lib/zookeeper" >> /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/conf/zoo.cfg
        echo "clientPort=2181" >> /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/conf/zoo.cfg
        echo "initLimit=5" >> /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/conf/zoo.cfg
        echo "syncLimit=2" >> /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/conf/zoo.cfg
        echo ${count.index + 1}
        echo "here was test"
        for i in $(seq 1 ${var.instance-count-zk}); do
            if [[ $i == ${count.index + 1} ]]; then
                echo "server.$i=0.0.0.0:2888:3888" >> /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/conf/zoo.cfg
            else
                echo "server.$i=${var.zookeeper-hostname}-$i:2888:3888" >> /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/conf/zoo.cfg
            fi
        done
        chown zookeeper:zookeeper /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/conf/zoo.cfg
        su zookeeper -c 'cd /home/zookeeper && /opt/zookeeper/apache-zookeeper-${var.zk-version}-bin/bin/zkServer.sh start'
    
    EOF
}