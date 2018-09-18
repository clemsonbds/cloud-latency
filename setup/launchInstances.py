#!/usr/bin/env python
import argparse
import sys
import json
import traceback
import time
import os

# Set the delay time and the max attempts for the waiter
delayTime = 5
waitAttempts = 240
thisDir = os.path.realpath(__file__).rsplit('/', 1)[0]


def main():
    parser = argparse.ArgumentParser(description='Launches Instances utilizing the network resources created utilizing the createNetworkBastionHost.py script in the way specified by the experimentType parameter given.')
    parser.add_argument('--create', action='store_true', help='Specifies that the script should create resources.')
    parser.add_argument('--delete', action='store_true', help='Specifies that the script should delete resources.')
    parser.add_argument('--name', help='Specifies the name of the experiment, this will be used when creating tags for the resources.', required=True)
    parser.add_argument('--region', help='Specifies the name of the region where the resources will be created. Defaults to us-east-1 for AWS and us-east1 for GCP', default=None)
    parser.add_argument('--profile', help='Specifies the name of the AWS credentials profile that you want to use, if not specified the default one is used.', default="default")
    parser.add_argument('--cloudProvider', help='Specifies the name of the experiment, this will be used when creating tags for the resources.', default="aws", choices=["aws", "gcp"])
    parser.add_argument('--keyName', help='Specifies the name of the SSH key that will be utilized to launch the bastion host.')
    parser.add_argument('--imageId', help='Specifies the Image that will be used to launch the bastion host. This defaults to AWS Linux in N. Virginia for AWS and to Debian 8 in South Carolina for GCP.', default=None)
    parser.add_argument('--instanceType', help='Specifies the Instance Type that will be used to launch the bastion host. This defaults to t2.micro for AWS and to g1-small for GCP.', default=None)
    parser.add_argument('--numInstances', help='Specifies the number of instances to launch. Must be an integer greater than 1. The default is 2 instances.', type=int, default=2)
    parser.add_argument('--experimentType', help='Specifies the type of experiment to launch. Options are multi-az and single-az.  Multi-az launches the instances in multiple AZs, and single-az launches all the instances in a single AZ. The default is single-az.', default='single-az', choices=['multi-az', 'single-az'])
    parser.add_argument('--placementGroup', help='Specifies the grouping strategy for instance placement.  Options are cluster and spread.  Cluster will attempt to locate the nodes near eachother in a single AZ, spread will attempt to maximize availability in either single or multi AZ.  Default is no explicit grouping.', default=None, choices=['cluster', 'spread'])
    parser.add_argument('--azs', help='Specifies the exact AZs that will be used to launch the experiments. If using single-az only one AZ may be listed, if using multi-az a comma seperated list of AZs must be used. This is only the letter distinguishing the AZ, not the entire AZ name (ex: a,b,f)')
    parser.add_argument('--projectId', help='Only required for GCP. Specifies the project that will be used to run the experiment in GCP.', default=None)

    args = vars(parser.parse_args())

    if args['delete']:
        if args['cloudProvider'] == "aws":
            # Get the default region if not specified via commandline
            if args['region'] is None:
                # Amazon Linux 2 AMI in N. Virginia
                region = "us-east-1"
            else:
                region = args['region']

            try:
                import botocore
                import botocore.session
                import botocore.exceptions
            except Exception as e:
                print("In order to create AWS resources, the botocore pip package is required. Please install this package using the following command:\npip install -U botocore\n and try running the script again.")
                sys.exit(0)

            client = None
            try:
                session = botocore.session.Session(profile=args['profile'])
                client = session.create_client("ec2", region_name=region)
            except Exception as e:
                if "NoCredentialsError: Unable to locate credentials" in ''.join(traceback.format_exc()):
                    print("Unable to create a botocore session to AWS. Please ensure that you have your credentials located in the ~/.aws/credentials file. If you do not already have this file you can create one yourself, the format is as follows:\n[default]\naws_access_key_id = YOUR_ACCESS_KEY\naws_secret_access_key = YOUR_SECRET_KEY")
                    sys.exit(0)
                else:
                    print("There was an issue attempting to create a botocore session to AWS.")
                    print("The traceback is: " + ''.join(traceback.format_exc()))
                    sys.exit(0)

            values = deleteInstancesAws(client, args['name'])
            if values['status'] != "success":
                print("There was an issue attempting to delete the instances for the experiment.")
                print(values['message'])
                sys.exit(0)

            os.system("rm -rf " + thisDir + "/instancesCreated-" + str(args['name']) + ".json")

            print("Successfully deleted the instances for the experiment: " + str(args['name']))
            sys.exit(0)

        elif args['cloudProvider'] == "gcp":
            projectId = None
            # Check to ensure that a project Id is passed
            if args['projectId'] is None:
                print("You must specify a Project Id when using GCP. Please specify the Project Id using the --projectId argument that corresponds to the project within your GCP account that you wish to create the resources in.")
                sys.exit(0)
            else:
                projectId = args['projectId']

            # Get the default region if not specified via commandline
            if args['region'] is None:
                region = "us-east1"
            else:
                region = args['region']

            try:
                from googleapiclient import discovery
                from googleapiclient.errors import HttpError
            except Exception as e:
                print("In order to create GCP resources, the Google API Client pip package is required. Please install this package using the following command:\npip install --upgrade google-api-python-client\n and try running the script again.")
                sys.exit(0)

            # Check to see if the user has an API key or credentials that we can utilize
            credsPath = None
            try:
                # Checking this variable because I have two GCP accounts and GCP doesn't allow for multiple profiles so I'm remapping here
                if os.environ['GOOGLE_APPLICATION_CREDS'] != "":
                    # Overwrite the default GCP account so that the correct account is utilized.
                    credsPath = os.environ['GOOGLE_APPLICATION_CREDS']
                    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credsPath
                elif os.environ['GOOGLE_APPLICATION_CREDENTIALS'] == "":
                    print("Unable to locate credentials for GCP in the current environment. This application looks for the GOOGLE_APPLICATION_CREDENTIALS environment variable and utilizes that key for making requests. You can generate this key if you do not have one by logging into the GCP console -> IAM and admin -> Credentials -> Service accounts -> Create Service Account. You will need to set a name for the new Service Account, Select the Owner Role, and Check the Furnish a new private key box. Download the generated file and save it to a secure location on your local machine. Then set the value of the GOOGLE_APPLICATION_CREDENTIALS environment variable to the full path to the downloaded Credentials file and then run this script again.")
                    sys.exit(0)
            except Exception:
                print("Unable to locate credentials for GCP in the current environment. This application looks for the GOOGLE_APPLICATION_CREDENTIALS environment variable and utilizes that key for making requests. You can generate this key if you do not have one by logging into the GCP console -> IAM and admin -> Credentials -> Service accounts -> Create Service Account. You will need to set a name for the new Service Account, Select the Owner Role, and Check the Furnish a new private key box. Download the generated file and save it to a secure location on your local machine. Then set the value of the GOOGLE_APPLICATION_CREDENTIALS environment variable to the full path to the downloaded Credentials file and then run this script again.")
                sys.exit(0)

            service = None
            try:
                service = discovery.build('compute', 'v1', cache_discovery=False)
            except Exception as e:
                print("There was an issue attempting to create a service to GCP.")
                print("The traceback is: " + ''.join(traceback.format_exc()))
                sys.exit(0)

            values = deleteInstancesGcp(service, args['name'], projectId, region)
            if values['status'] != "success":
                print("There was an issue attempting to delete the instances for the experiment.")
                print(values['message'])
                sys.exit(0)

            os.system("rm -rf " + thisDir + "/instancesCreated-" + str(args['name']) + ".json")

            print("Successfully deleted the instances for the experiment: " + str(args['name']))
            sys.exit(0)

    if args['azs'] is None:
        print("One or more AZs must be specified for creation of instances.")
        sys.exit(0)

    # the cluster placement group only makes sense in a single AZ
    if args['cloudProvider'] == "aws":
        if args['placementGroup'] == 'cluster' and args['experimentType'] != 'single-az':
            print("The cluster placement group can only be used with the single-az experiment type.")
            sys.exit(0)
    elif args['placementGroup'] is not None:
        print("Placement Groups are only valid when using AWS as the Cloud Provider. Please remove the --placementGroup option and run the script again.")
        sys.exit(0)

    # Validate and ensure that if the single-az experiment type is chosen we only have one AZ and that we have multiple AZs for the multi-az experiment
    if args['experimentType'] == 'single-az' and ',' in args['azs']:
        print("Only one AZ can be specified when using the single-az experiment type.")
        sys.exit(0)

    if args['experimentType'] == "multi-az" and ',' not in args['azs']:
        print("Multiple AZs are required when executing the multi-az experiment type.")
        sys.exit(0)

    if args['create']:
        if args['cloudProvider'] == "aws":
            # TODO Add in way to pass in UserData from file
            userData = ""

            if args['keyName'] is None:
                print("A key name is required to create AWS resources.")
                sys.exit(0)
        
            # Get the default AMI for the bastion host if not specified via commandline
            if args['imageId'] is None:
                # Amazon Linux 2 AMI in N. Virginia
                imageId = "ami-b70554c8"
            else:
                imageId = args['imageId']

            # Get the default region if not specified via commandline
            if args['region'] is None:
                # Amazon Linux 2 AMI in N. Virginia
                region = "us-east-1"
            else:
                region = args['region']

            # Set the default Instance Type if not specified via commandline
            if args['instanceType'] is None:
                instanceType = "t2.small"
            else:
                instanceType = args['instanceType']

            try:
                import botocore
                import botocore.session
                import botocore.exceptions
            except Exception as e:
                print("In order to create AWS resources, the botocore pip package is required. Please install this package using the following command:\npip install -U botocore\n and try running the script again.")
                sys.exit(0)

            client = None
            try:
                session = botocore.session.Session(profile=args['profile'])
                client = session.create_client("ec2", region_name=region)
            except Exception as e:
                if "NoCredentialsError: Unable to locate credentials" in ''.join(traceback.format_exc()):
                    print("Unable to create a botocore session to AWS. Please ensure that you have your credentials located in the ~/.aws/credentials file. If you do not already have this file you can create one yourself, the format is as follows:\n[default]\naws_access_key_id = YOUR_ACCESS_KEY\naws_secret_access_key = YOUR_SECRET_KEY")
                    sys.exit(0)
                else:
                    print("There was an issue attempting to create a botocore session to AWS.")
                    print("The traceback is: " + ''.join(traceback.format_exc()))
                    sys.exit(0)

            values = launchInstancesAws(client, imageId, instanceType, args['numInstances'], args['experimentType'], args['placementGroup'], args['azs'], args['keyName'], args['name'], region, userData)

            if values['payload'] is not None:
                dumpResourcesCreatedToFile(values['payload']['instancesCreated'], args['name'])

            if values['status'] != "success":
                print("There was an issue attempting to launch the instances for the experiment.")
                print(values['message'])
            else:
                print("Successfully created the instances for the experiment: " + str(args['name']))

            sys.exit(0)
        elif args['cloudProvider'] == "gcp":
            # TODO Add in way to pass in UserData from file
            userData = ""
            projectId = None
            # Check to ensure that a project Id is passed
            if args['projectId'] is None:
                print("You must specify a Project Id when using GCP. Please specify the Project Id using the --projectId argument that corresponds to the project within your GCP account that you wish to create the resources in.")
                sys.exit(0)
            else:
                projectId = args['projectId']

            # Get the default AMI for the bastion host if not specified via commandline
            if args['imageId'] is None:
                # Image to use for launching the instances to benchmark CentOS 7
                imageId = "projects/centos-cloud/global/images/centos-7-v20180815"
            else:
                imageId = args['imageId']

            # Get the default region if not specified via commandline
            if args['region'] is None:
                region = "us-east1"
            else:
                region = args['region']

            # Set the default Instance Type if not specified via commandline
            if args['instanceType'] is None:
                instanceType = "g1-small"
            else:
                instanceType = args['instanceType']

            try:
                from googleapiclient import discovery
                from googleapiclient.errors import HttpError
            except Exception as e:
                print("In order to create GCP resources, the Google API Client pip package is required. Please install this package using the following command:\npip install --upgrade google-api-python-client\n and try running the script again.")
                sys.exit(0)

            # Check to see if the user has an API key or credentials that we can utilize
            credsPath = None
            try:
                # Checking this variable because I have two GCP accounts and GCP doesn't allow for multiple profiles so I'm remapping here
                if os.environ['GOOGLE_APPLICATION_CREDS'] != "":
                    # Overwrite the default GCP account so that the correct account is utilized.
                    credsPath = os.environ['GOOGLE_APPLICATION_CREDS']
                    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = credsPath
                elif os.environ['GOOGLE_APPLICATION_CREDENTIALS'] == "":
                    print("Unable to locate credentials for GCP in the current environment. This application looks for the GOOGLE_APPLICATION_CREDENTIALS environment variable and utilizes that key for making requests. You can generate this key if you do not have one by logging into the GCP console -> IAM and admin -> Credentials -> Service accounts -> Create Service Account. You will need to set a name for the new Service Account, Select the Owner Role, and Check the Furnish a new private key box. Download the generated file and save it to a secure location on your local machine. Then set the value of the GOOGLE_APPLICATION_CREDENTIALS environment variable to the full path to the downloaded Credentials file and then run this script again.")
                    sys.exit(0)
            except Exception:
                print("Unable to locate credentials for GCP in the current environment. This application looks for the GOOGLE_APPLICATION_CREDENTIALS environment variable and utilizes that key for making requests. You can generate this key if you do not have one by logging into the GCP console -> IAM and admin -> Credentials -> Service accounts -> Create Service Account. You will need to set a name for the new Service Account, Select the Owner Role, and Check the Furnish a new private key box. Download the generated file and save it to a secure location on your local machine. Then set the value of the GOOGLE_APPLICATION_CREDENTIALS environment variable to the full path to the downloaded Credentials file and then run this script again.")
                sys.exit(0)

            service = None
            try:
                service = discovery.build('compute', 'v1', cache_discovery=False)
            except Exception as e:
                print("There was an issue attempting to create a service to GCP.")
                print("The traceback is: " + ''.join(traceback.format_exc()))
                sys.exit(0)

            values = launchInstancesGcp(service, imageId, instanceType, args['numInstances'], args['experimentType'], args['azs'], args['keyName'], args['name'], region, userData, projectId)
            if values['payload'] is not None:
                dumpResourcesCreatedToFile(values['payload']['instancesCreated'], args['name'])

            if values['status'] != "success":
                print("There was an issue attempting to launch the instances for the experiment.")
                print(values['message'])
            else:
                print("Successfully created the instances for the experiment: " + str(args['name']))

            sys.exit(0)


def launchInstancesAws(client, imageId, instanceType, numInstances, experimentType, placementGroup, azs, keyName, name, region, userData):
    # Load the AZs into a list
    azs = azs.split(",")

    instancesCreated = {'instances': []}

    # Load the network resources that were created by the previous script for this experiment name
    createdNetworkResources = None
    values = loadNetworkResources(name)
    if values['status'] != "success":
        return values
    else:
        createdNetworkResources = values['payload']

    placementStrategy = {}

    # Create a Placement Group that we can utilize for launching instances into
    if placementGroup is not None:
        try:
            print("Creating the Placement Group.")
            placementStrategy['GroupName'] = str(name) + "-PlacementGroup" # hold for launching instances below
            response = client.create_placement_group(GroupName=placementStrategy['GroupName'], Strategy=placementGroup)
            instancesCreated['placementGroup'] = placementStrategy['GroupName']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"instancesCreated": instancesCreated}}

    if experimentType == "single-az":
        subnetId = None
        for subnet in createdNetworkResources['privateSubnets']:
            if subnet['az'] == str(region) + azs[0]:
                subnetId = subnet['subnetId']

        if subnetId is None:
            return {"status": "error", "message": "Unable to find the subnetId for the AZ: " + str(str(region) + azs[0]), "payload": {"instancesCreated": instancesCreated}}

        # Launch all the instances into the single AZ provided
        try:
            print("Launching the instances.")

            placementStrategy['AvailabilityZone'] = str(region) + azs[0] # AZ and optional placement group
            response = client.run_instances(ImageId=imageId, MinCount=numInstances, MaxCount=numInstances, KeyName=keyName, UserData=userData, InstanceType=instanceType, Monitoring={"Enabled": False}, SubnetId=subnetId, DisableApiTermination=False, InstanceInitiatedShutdownBehavior="stop", SecurityGroupIds=[createdNetworkResources['privateSecurityGroup']], Placement=placementStrategy)
            
            # Get the instanceId from the response
            for instance in response['Instances']:
                instancesCreated['instances'].append(instance['InstanceId'])
            time.sleep(5)

            # Wait until the instance is in the Running state
            print("Waiting for the Instances to become ready.")
            waiter = client.get_waiter('instance_running')
            waiter.wait(InstanceIds=instancesCreated['instances'], WaiterConfig={'Delay': delayTime, 'MaxAttempts': waitAttempts})

            response = client.create_tags(Resources=instancesCreated['instances'], Tags=[{'Key': 'Name', 'Value': str(name) + "-Instance"}])
        except Exception:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"instancesCreated": instancesCreated}}
    
    elif experimentType == "multi-az":
        # Launch a certain number of instances into each AZ specified, will attempt to launch them evenly throughout the AZs depending on the number of instances and number of AZs specified
        numAzs = len(azs)

        if (numInstances % numAzs) == 0:
            print("The number of instances is evenly divisible by the number of AZs specified, all AZs will get the same number of instances.")
        elif numInstances < numAzs:
            print("There were more AZs specified then the requested number of instances, some AZs may not get instances.")
        else:
            print("The number of instances is not evenly divisible by the number of AZs specified, some AZs may have more instances then others.")

        # build a dict mapping each az to the number of instances
        azDistribution = {}

        # initialize all to zero
        for az in azs:
            azDistribution[az] = 0

        # distribute them round robin
        for index in range(numInstances):
            az = azs[index % numAzs] # choose the next az
            azDistribution[az] += 1

        print("Launching the instances.")

        for az, numThisAz in azDistribution.items():

            if numThisAz == 0:
                continue

            placementStrategy['AvailabilityZone'] = str(region) + az # AZ and optional placement group

            subnetId = None
            for subnet in createdNetworkResources['privateSubnets']:
                if subnet['az'] == placementStrategy['AvailabilityZone']:
                    subnetId = subnet['subnetId']

            if subnetId is None:
                return {"status": "error", "message": "Unable to find the subnetId for the AZ: " + str(str(region) + az), "payload": {"instancesCreated": instancesCreated}}

            try:
                response = client.run_instances(ImageId=imageId, MinCount=numThisAz, MaxCount=numThisAz, KeyName=keyName, UserData=userData, InstanceType=instanceType, Monitoring={"Enabled": False}, SubnetId=subnetId, DisableApiTermination=False, InstanceInitiatedShutdownBehavior="stop", SecurityGroupIds=[createdNetworkResources['privateSecurityGroup']], Placement=placementStrategy)
                
                # Get the instanceId from the response
                for instance in response['Instances']:
                    instancesCreated['instances'].append(instance['InstanceId'])

            except Exception:
                return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"instancesCreated": instancesCreated}}

        # Wait until the instance is in the Running state
        print("Waiting for the Instances to be ready.")
        waiter = client.get_waiter('instance_running')
        waiter.wait(InstanceIds=instancesCreated['instances'], WaiterConfig={'Delay': delayTime, 'MaxAttempts': waitAttempts})

        response = client.create_tags(Resources=instancesCreated['instances'], Tags=[{'Key': 'Name', 'Value': str(name) + "-Instance"}])
    else:
        return {"status": "error", "message": "Invalid experiment type specified: " + str(experimentType), "payload": {"instancesCreated": {"instancesCreated": instancesCreated}}}

    return {"status": "success", "message": "All the instances have been launched successfully.", "payload": {"instancesCreated": instancesCreated}}


def launchInstancesGcp(service, imageId, instanceType, numInstances, experimentType, azs, keyName, name, region, userData, projectId):
    # Load the AZs into a list
    azs = azs.split(",")

    instancesCreated = {'instances': {}}

    # Load the network resources that were created by the previous script for this experiment name
    createdNetworkResources = None
    values = loadNetworkResources(name)
    if values['status'] != "success":
        return values
    else:
        createdNetworkResources = values['payload']

    if experimentType == "single-az":
        zone = str(region) + "-" + azs[0]
        instancesCreated['instances'][zone] = []
        subnetId = None
        for subnet in createdNetworkResources['privateSubnets']:
            if subnet['az'] == zone:
                subnetId = subnet['subnetId']

        if subnetId is None:
            return {"status": "error", "message": "Unable to find the subnetId for the AZ: " + str(str(region) + azs[0]), "payload": {"instancesCreated": instancesCreated}}

        numInstancesCreated = 0
        listOfOperationsToWaitFor = []
        print("Launching the instances.")
        while numInstancesCreated < numInstances:
            try:
                import uuid
                uniquePart = str(uuid.uuid4().get_hex().lower()[0:4])
                uniqueName = str(name) + "-" + str(uniquePart)

                instance_body = createInstanceRequestBody(uniqueName, region, zone, instanceType, userData, ['priv'], imageId, projectId, subnetId, name)
                instance = service.instances().insert(project=projectId, zone=zone, body=instance_body)
                request = instance.execute()
                instancesCreated['instances'][zone].append(uniqueName)
                listOfOperationsToWaitFor.append(request['name'])
                numInstancesCreated += 1
            except Exception as e:
                return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"instancesCreated": instancesCreated}}

        # Wait for all the instances to become running
        print("Waiting for the Instances to be ready.")
        for operation in listOfOperationsToWaitFor:
            result = waitForOperationToComplete(service, projectId, operation, zone=zone)
            if result['status'] != "success":
                # There was an error while waiting for the resource operation to complete
                return {"status": "error", "message": result['payload']['error'], "payload": {"instancesCreated": instancesCreated}}

    elif experimentType == "multi-az":
        # Launch a certain number of instances into each AZ specified, will attempt to launch them evenly throughout the AZs depending on the number of instances and number of AZs specified
        numAzs = len(azs)

        if (numInstances % numAzs) == 0:
            print("The number of instances is evenly divisible by the number of AZs specified, all AZs will get the same number of instances.")
        elif numInstances < numAzs:
            print("There were more AZs specified then the requested number of instances, some AZs may not get instances.")
        else:
            print("The number of instances is not evenly divisible by the number of AZs specified, some AZs may have more instances then others.")

        # build a dict mapping each az to the number of instances
        azDistribution = {}

        # initialize all to zero
        for az in azs:
            azDistribution[az] = 0

        # distribute them round robin
        for index in range(numInstances):
            az = azs[index % numAzs] # choose the next az
            azDistribution[az] += 1

        listOfOperationsToWaitFor = {}

        print("Launching the instances.")
        for az, numThisAz in azDistribution.items():
            zone = str(region) + "-" + az
            instancesCreated['instances'][zone] = []
            listOfOperationsToWaitFor[zone] = []
            if numThisAz == 0:
                continue

            subnetId = None
            for subnet in createdNetworkResources['privateSubnets']:
                if subnet['az'] == zone:
                    subnetId = subnet['subnetId']

            if subnetId is None:
                return {"status": "error", "message": "Unable to find the subnetId for the AZ: " + str(zone), "payload": {"instancesCreated": instancesCreated}}

            numInstancesCreated = 0
            while numInstancesCreated < numThisAz:
                try:
                    import uuid
                    uniquePart = str(uuid.uuid4().get_hex().lower()[0:4])
                    uniqueName = str(name) + "-" + str(uniquePart)

                    instance_body = createInstanceRequestBody(uniqueName, region, zone, instanceType, userData, ['priv'], imageId, projectId, subnetId, name)
                    instance = service.instances().insert(project=projectId, zone=zone, body=instance_body)
                    request = instance.execute()
                    instancesCreated['instances'][zone].append(uniqueName)
                    listOfOperationsToWaitFor[zone].append(request['name'])
                    numInstancesCreated += 1
                except Exception as e:
                    return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"instancesCreated": instancesCreated}}

        # Wait for all the instances to become running
        print("Waiting for the Instances to be ready.")
        for az in listOfOperationsToWaitFor:
            for operation in listOfOperationsToWaitFor[az]:
                result = waitForOperationToComplete(service, projectId, operation, zone=az)
                if result['status'] != "success":
                    # There was an error while waiting for the resource operation to complete
                    return {"status": "error", "message": result['payload']['error'], "payload": {"instancesCreated": instancesCreated}}

    return {"status": "success", "message": "All the instances have been launched successfully.", "payload": {"instancesCreated": instancesCreated}}


def deleteInstancesAws(client, name):
    resourcesToDelete = None

    # Load the resources to delete from the file written out by the create function
    with open(thisDir + "/instancesCreated-" + str(name) + ".json") as outputFile:
        resourcesToDelete = json.load(outputFile)

    # Delete the Bastion Host
    if 'instances' in resourcesToDelete and len(resourcesToDelete['instances']) > 0:
        try:
            print("Deleting the Instances.")
            response = client.terminate_instances(InstanceIds=resourcesToDelete['instances'])

            # Wait until the instance is in the Terminate state
            print("Waiting for the Instances to terminate.")
            waiter = client.get_waiter('instance_terminated')
            waiter.wait(InstanceIds=resourcesToDelete['instances'], WaiterConfig={'Delay': delayTime, 'MaxAttempts': waitAttempts})
            del resourcesToDelete['instances']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    # Delete the Placement Group
    if 'placementGroup' in resourcesToDelete:
        try:
            print("Deleting the Placement Group.")
            response = client.delete_placement_group(GroupName=resourcesToDelete['placementGroup'])
            del resourcesToDelete['placementGroup']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    return {"status": "success", "message": "Successfully deleted the instances.", "payload": {"resourcesToDelete": resourcesToDelete}}


def deleteInstancesGcp(service, name, projectId, region):
    resourcesToDelete = None
    listOfOperationsToWaitFor = {}

    # Load the resources to delete from the file written out by the create function
    with open(thisDir + "/instancesCreated-" + str(name) + ".json") as outputFile:
        resourcesToDelete = json.load(outputFile)

    try:
        print("Deleting the Instances.")
        import copy
        instanceList = copy.deepcopy(resourcesToDelete['instances'])
        for az in instanceList:
            listOfOperationsToWaitFor[az] = []
            for instance in instanceList[az]:
                try:
                    instanceTermination = service.instances().delete(project=projectId, zone=az, instance=instance)
                    deletion = instanceTermination.execute()
                    listOfOperationsToWaitFor[az].append(deletion['name'])
                    resourcesToDelete['instances'][az].remove(instance)
                except Exception as e:
                    print("There was an error attempting to delete the instance: " + str(instance))
                    print(''.join(traceback.format_exc()))

        # Wait until the instance is in the Terminate state
        print("Waiting for the Instances to terminate.")
        for az in listOfOperationsToWaitFor:
            for operation in listOfOperationsToWaitFor[az]:
                result = waitForOperationToComplete(service, projectId, operation, zone=az)
                if result['status'] != "success":
                    # There was an error while waiting for the resource operation to complete
                    return {"status": "error", "message": result['payload']['error'], "payload": {"resourcesToDelete": resourcesToDelete}}
        del resourcesToDelete['instances']
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    return {"status": "success", "message": "Successfully deleted the instances.", "payload": {"resourcesToDelete": resourcesToDelete}}


def createInstanceRequestBody(name, region, zone, instanceType, userData, tags, imageId, projectId, subnet, experimentName):
    instance_body = {
                "name": name,
                "zone": zone,
                "minCpuPlatform": "Automatic",
                "machineType": '/zones/' + zone + '/machineTypes/' + str(instanceType),
                "metadata": {
                    "items": [
                        {
                            "key": "startup-script",
                            "value": userData
                        },
                    ]
                },
                "tags": {
                    "items": tags
                },
                "disks": [
                    {
                        "type": "PERSISTENT",
                        "boot": "true",
                        "mode": "READ_WRITE",
                        "autoDelete": "true",
                        "deviceName": name,
                        "initializeParams": {
                            "sourceImage": str(imageId),
                            "diskType": "projects/" + str(projectId) + "/zones/" + zone + "/diskTypes/pd-ssd"
                        }
                    }
                ],
                "canIpForward": "true",
                "networkInterfaces": [
                    {
                        "subnetwork": "projects/" + str(projectId) + "/regions/" + str(region) + "/subnetworks/" + subnet
                    }
                ],
                "description": "",
                "labels": {
                    "instance-type": "internal",
                    "experiment-name": str(experimentName)
                },
                "scheduling": {
                    "preemptible": "false",
                    "onHostMaintenance": "MIGRATE",
                    "automaticRestart": "true"
                },
                "deletionProtection": "false",
            }

    return instance_body


def waitForOperationToComplete(service, projectId, operation, zone=None, region=None):
    # https://cloud.google.com/compute/docs/regions-zones/global-regional-zonal-resources
    # print('Waiting for ' + operation + ' to finish...')

    while True:
        if zone is not None:
            # Wait for a zone operation to complete
            result = service.zoneOperations().get(project=projectId, zone=zone, operation=operation).execute()
        elif region is not None:
            # Wait for a region operation to complete
            result = service.regionOperations().get(project=projectId, region=region, operation=operation).execute()
        else:
            # Wait for a global operation to complete
            result = service.globalOperations().get(project=projectId, operation=operation).execute()

        if result['status'] == 'DONE':
            if 'error' in result:
                return {"status": "error", "payload": {"error": str(result['error']), "traceback": ''.join(traceback.format_stack())}}
            else:
                # print("The operation has completed successfully")
                return {"status": "success", "payload": "The operation completed successfully."}
        time.sleep(5)


def loadNetworkResources(name):
    try:
        with open(thisDir + "/networkResourcesCreated-" + str(name) + ".json") as outputFile:
            networkResourcesCreated = json.load(outputFile)
            return {"status": "success", "message": "Successfully loaded the network resources", "payload": networkResourcesCreated}
    except Exception:
        return {"status": "error", "message": "Unable to load the network resources created for the experiment: " + str(name), "payload": None}


def dumpResourcesCreatedToFile(instancesCreated, name):
    try:
        with open(thisDir + "/instancesCreated-" + str(name) + ".json", "w") as outputFile:
            json.dump(instancesCreated, outputFile, sort_keys=True, indent=4, separators=(',', ': '))
    except Exception:
        return {"status": "error", "message": "Unable to save the instances created for the experiment: " + str(name), "payload": None}


main()
