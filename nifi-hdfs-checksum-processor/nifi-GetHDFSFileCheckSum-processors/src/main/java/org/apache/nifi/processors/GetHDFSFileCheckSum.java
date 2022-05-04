/*
 * Copyright 2022 Google LLC
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.nifi.processors;

import java.util.Base64;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileChecksum;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.security.AccessControlException;
import org.apache.hadoop.security.UserGroupInformation;
import org.apache.nifi.annotation.behavior.InputRequirement;
import org.apache.nifi.annotation.behavior.InputRequirement.Requirement;
import org.apache.nifi.annotation.behavior.Restricted;
import org.apache.nifi.annotation.behavior.Restriction;
import org.apache.nifi.annotation.behavior.SupportsBatching;
import org.apache.nifi.annotation.behavior.WritesAttribute;
import org.apache.nifi.annotation.documentation.CapabilityDescription;
import org.apache.nifi.annotation.documentation.Tags;
import org.apache.nifi.components.PropertyDescriptor;
import org.apache.nifi.components.RequiredPermission;
import org.apache.nifi.expression.ExpressionLanguageScope;
import org.apache.nifi.flowfile.FlowFile;
import org.apache.nifi.flowfile.attributes.CoreAttributes;
import org.apache.nifi.processor.ProcessContext;
import org.apache.nifi.processor.ProcessSession;
import org.apache.nifi.processor.Relationship;
import org.apache.nifi.processor.exception.ProcessException;
import org.apache.nifi.processor.util.StandardValidators;
import org.apache.nifi.processors.hadoop.AbstractHadoopProcessor;
import org.apache.nifi.util.StopWatch;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.security.PrivilegedAction;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.TimeUnit;

@SupportsBatching
@InputRequirement(Requirement.INPUT_REQUIRED)
@Tags({"hadoop", "hdfs", "hash", "checksum", "md5"})
@CapabilityDescription("Retrieves checksum of the file present in HDFS. "
    + "The file in HDFS is left intact without any changes being made to it.")
@WritesAttribute(attribute="hdfs.failure.reason", description="When a FlowFile is routed to 'failure', this attribute is added indicating why the checksum of file could "
    + "not be fetched from HDFS")

@Restricted(restrictions = {
    @Restriction(
        requiredPermission = RequiredPermission.READ_DISTRIBUTED_FILESYSTEM,
        explanation = "Provides operator the ability to retrieve checksum of file that NiFi has access to in HDFS or the local filesystem.")
})
public class GetHDFSFileCheckSum extends AbstractHadoopProcessor {

    static final PropertyDescriptor FILENAME = new PropertyDescriptor.Builder()
        .name("HDFS Filename")
        .description("The name of the HDFS file to retrieve checksum")
        .required(true)
        .expressionLanguageSupported(ExpressionLanguageScope.FLOWFILE_ATTRIBUTES)
        .defaultValue("${path}/${filename}")
        .addValidator(StandardValidators.ATTRIBUTE_EXPRESSION_LANGUAGE_VALIDATOR)
        .build();

    static final Relationship REL_SUCCESS = new Relationship.Builder()
        .name("success")
        .description("FlowFiles will be routed to this relationship once they have been updated with the checksum of HDFS file")
        .build();
    static final Relationship REL_FAILURE = new Relationship.Builder()
        .name("failure")
        .description("FlowFiles will be routed to this relationship if checksum of the HDFS file cannot be retrieved and trying again will likely not be helpful. "
            + "This would occur, for instance, if the file is not found or if there is a permissions issue")
        .build();
    static final Relationship REL_COMMS_FAILURE = new Relationship.Builder()
        .name("comms.failure")
        .description("FlowFiles will be routed to this relationship if checksum of the HDFS file cannot be retrieve due to a communications failure. "
            + "This generally indicates that the Fetch should be tried again.")
        .build();

    @Override
    protected List<PropertyDescriptor> getSupportedPropertyDescriptors() {
        final List<PropertyDescriptor> props = new ArrayList<>(properties);
        props.add(FILENAME);
        return props;
    }

    @Override
    public Set<Relationship> getRelationships() {
        final Set<Relationship> relationships = new HashSet<>();
        relationships.add(REL_SUCCESS);
        relationships.add(REL_FAILURE);
        relationships.add(REL_COMMS_FAILURE);
        return relationships;
    }

    @Override
    public void onTrigger(final ProcessContext context, final ProcessSession session) throws ProcessException {
        FlowFile flowFile = session.get();
        if ( flowFile == null ) {
            return;
        }

        // Set this property to get Composite CRC checksum otherwise we will get MD5 of the CRC checksum of individual chunks
        // which is not useful for validation of comparison purpose
        Configuration conf = getConfiguration();
        conf.set("dfs.checksum.combine.mode", "COMPOSITE_CRC");

        final UserGroupInformation ugi = getUserGroupInformation();
        final String filenameValue = getPath(context, flowFile);
        final FileSystem hdfs;
        final Path path;
        try {
            hdfs = getFileSystem(conf);
            path = getNormalizedPath(getPath(context, flowFile));
        } catch (IllegalArgumentException | IOException e) {
            getLogger().error("Failed to retrieve checksum from {} for {} due to {}; routing to failure", new Object[] {filenameValue, flowFile, e});
            flowFile = session.putAttribute(flowFile, getAttributePrefix() + ".failure.reason", e.getMessage());
            flowFile = session.penalize(flowFile);
            session.transfer(flowFile, getFailureRelationship());
            return;
        }

        final StopWatch stopWatch = new StopWatch(true);
        final FlowFile finalFlowFile = flowFile;

        ugi.doAs(new PrivilegedAction<Object>() {
            @Override
            public Object run() {
                Configuration conf = getConfiguration();
                FlowFile flowFile = finalFlowFile;
                final Path qualifiedPath = path.makeQualified(hdfs.getUri(), hdfs.getWorkingDirectory());
                try {
                    final String outputFilename;
                    outputFilename = path.getName();;

                    FileChecksum computed_checksum = hdfs.getFileChecksum(path);
                    String b64_checksum = Base64.getEncoder().encodeToString(computed_checksum.getBytes());
                    String checksum_algorithm = computed_checksum.getAlgorithmName();

                    flowFile = session.putAttribute(flowFile, CoreAttributes.FILENAME.key(), outputFilename);
                    flowFile = session.putAttribute(flowFile,"checksum.value" , b64_checksum);
                    flowFile = session.putAttribute(flowFile, "checksum.algorithm", checksum_algorithm);

                    stopWatch.stop();

                    getLogger().info("Successfully retrieve checksum from {} for {} in {}", new Object[] {qualifiedPath, flowFile, stopWatch.getDuration()});
                    session.getProvenanceReporter().fetch(flowFile, qualifiedPath.toString(), stopWatch.getDuration(TimeUnit.MILLISECONDS));
                    session.transfer(flowFile, getSuccessRelationship());
                } catch (final FileNotFoundException | AccessControlException e) {
                    getLogger().error("Failed to retrieve checksum from {} for {} due to {}; routing to failure", new Object[] {qualifiedPath, flowFile, e});
                    flowFile = session.putAttribute(flowFile, getAttributePrefix() + ".failure.reason", e.getMessage());
                    flowFile = session.penalize(flowFile);
                    session.transfer(flowFile, getFailureRelationship());
                } catch (final IOException e) {
                    getLogger().error("Failed to retrieve checksum from {} for {} due to {}; routing to comms.failure", new Object[] {qualifiedPath, flowFile, e});
                    flowFile = session.penalize(flowFile);
                    session.transfer(flowFile, getCommsFailureRelationship());
                }

                return null;
            }
        });
    }

    protected Relationship getSuccessRelationship() {
        return REL_SUCCESS;
    }

    protected Relationship getFailureRelationship() {
        return REL_FAILURE;
    }

    protected Relationship getCommsFailureRelationship() {
        return REL_COMMS_FAILURE;
    }

    protected String getPath(final ProcessContext context, final FlowFile flowFile) {
        return context.getProperty(FILENAME).evaluateAttributeExpressions(flowFile).getValue();
    }

    protected String getAttributePrefix() {
        return "hdfs";
    }

}
