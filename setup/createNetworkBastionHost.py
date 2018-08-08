#!/usr/bin/env python3
import argparse
import sys
import json
import traceback
import time
import os

thisDir = os.path.realpath(__file__).rsplit('/', 1)[0]

def main():
    parser = argparse.ArgumentParser(description='Creates a VPC network with a 10.0.0.0/16 CIDR that contains a public (10.0.1.0/24) and private subnet for each Availability Zone in the Region (10.0.2.0/24 - 10.0.X.0/24) and a bastion host within the public subnet.')
    parser.add_argument('--create', action='store_true', help='Specifies that the script should create resources.')
    parser.add_argument('--delete', action='store_true', help='Specifies that the script should delete resources.')
    parser.add_argument('--name', help='Specifies the name of the experiment, this will be used when creating tags for the resources.', required=True)
    parser.add_argument('--region', help='Specifies the name of the region where the resources will be created. Defaults to us-east-1 for AWS and us-central1 for GCP', default=None)
    parser.add_argument('--profile', help='Specifies the name of the AWS credentials profile that you want to use, if not specified the default one is used.', default="default")
    parser.add_argument('--cloudProvider', help='Specifies the name of the experiment, this will be used when creating tags for the resources.', default="aws", choices=["aws", "gcp"])
    parser.add_argument('--keyName', help='Specifies the name of the SSH key that will be utilized to launch the bastion host.')
    parser.add_argument('--imageId', help='Specifies the Image that will be used to launch the bastion host. This defaults to AWS Linux in N. Virginia for AWS and to Debian 8 in Central Iowa for GCP.', default=None)
    parser.add_argument('--instanceType', help='Specifies the Instance Type that will be used to launch the bastion host. This defaults to t2.micro for AWS and to g1-small for GCP.', default=None)
    args = vars(parser.parse_args())

    if args['create']:
        # Need to create the network resources and bastion host
        if args['cloudProvider'] == "aws":

            # NAT AMI Id:
            natImage = "ami-980554e7"

            if args['keyName'] is None:
                print("A key name is required to create AWS resources.")
                sys.exit(0)
            
            # Get the default AMI for the bastion host if not specified via commandline
            if args['imageId'] is None:
                # Amazon Linux 2 AMI in N. Virginia
                imageId = "ami-b70554c8"
            else:
                imageId = args['imageId']

            # Set the default Instance Type if not specified via commandline
            if args['instanceType'] is None:
                instanceType = "t2.small"
            else:
                instanceType = args['instanceType']

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

            values = createAwsResources(client, args['name'], region, args['keyName'], imageId, instanceType, natImage)
            if values['status'] != "success":
                if "NoCredentialsError: Unable to locate credentials" in ''.join(traceback.format_exc()):
                    print("Unable to locate your AWS credentials. Please ensure that you have your credentials located in the ~/.aws/credentials file. If you do not already have this file you can create one yourself, the format is as follows:\n[default]\naws_access_key_id = YOUR_ACCESS_KEY\naws_secret_access_key = YOUR_SECRET_KEY")
                    sys.exit(0)
                else:
                    createdResourceString = ""
                    if len(values['payload']['resourcesCreated']) > 0:
                        # Dump out the resource Ids to a file that will be read in by the delete function to delete the resources
                        dumpResourcesCreatedToFile(values['payload']['resourcesCreated'], args['name'])

                        # Iterate over the keys of the resources created so that they can be listed for the user
                        for resource in values['payload']['resourcesCreated'].keys():
                            createdResourceString += str(resource) + ", "
                        createdResourceString[:len(createdResourceString)-2]
                        print("There was an issue creating the AWS resources. The following resources were created before the error was encountered: " + str(createdResourceString) + ".")
                    else:
                        print("There was an issue creating the AWS resources.")
                    print("The traceback is:\n" + values['message'])
                    sys.exit(0)
            else:
                # Dump out the resource Ids to a file that will be read in by the delete function to delete the resources
                dumpResourcesCreatedToFile(values['payload']['resourcesCreated'], args['name'])
                print("Successfully created the networking resources and the bastion host.")
                sys.exit(0)


    elif args['delete']:
        # Need to delete the network resources and bastion host for the experiment name
        if args['name'] == "None":
            # If no name was given print an error and exit
            print("The name argument must be specified when deleting resources. Please specify a name and try again.")
            sys.exit(0)
        else:
            # Delete the resources tagged with the appropriate name
            if args['cloudProvider'] == "aws":
                # Get the default region if not specified via commandline
                if args['region'] is None:
                    # Amazon Linux 2 AMI in N. Virginia
                    region = "us-east-1"
                else:
                    region = args['region']

                client = None
                try:
                    import botocore
                    import botocore.session
                    import botocore.exceptions
                except Exception as e:
                    print("In order to create AWS resources, the botocore pip package is required. Please install this package using the following command:\npip install -U botocore\n and try running the script again.")
                    sys.exit(0)

                try:
                    session = botocore.session.Session(profile=args['profile'])
                    client = session.create_client("ec2", region_name=args['region'])
                except Exception as e:
                    print("Unable to create a botocore session to AWS. Please ensure that you have your credentials located in the ~/.aws/credentials file. If you do not already have this file you can create one yourself, the format is as follows:\n[default]\naws_access_key_id = YOUR_ACCESS_KEY\naws_secret_access_key = YOUR_SECRET_KEY")
                    sys.exit(0)

                values = deleteAwsResources(client, args['name'])
                if values['status'] != "success":
                    print("There was an issue attempting to delete one of the resources. The remaining resources have been written out to the file: networkResourcesCreated-" + str(args['name']) + ".json")
                    print(values['message'])
                    # Dump out the resource Ids to a file that will be read in by the delete function to delete the resources
                    dumpResourcesCreatedToFile(values['payload']['resourcesToDelete'], args['name'])
                    sys.exit(0)
                else:
                    print("The resources have been successfully deleted.")
                    os.system("rm -f " + thisDir + "/networkResourcesCreated-" + str(args['name']) + ".json")
                    sys.exit(0)


def createAwsResources(client, name, region, keyName, imageId, instanceType, natImage):
    resourcesCreated = {}
    # First we need to create the VPC
    try:
        print("Creating the VPC.")
        response = client.create_vpc(CidrBlock='10.0.0.0/16', InstanceTenancy='default')
        resourcesCreated['vpc'] = response['Vpc']['VpcId']
        time.sleep(5)

        # Tag the resource with a specific name so we can filter on it later
        response = client.create_tags(Resources=[resourcesCreated['vpc']], Tags=[{'Key': 'Name', 'Value': str(name) + "-Vpc"}])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Second create the Public Subnet
    try:
        print("Creating the Public Subnet.")
        response = client.create_subnet(AvailabilityZone=str(region) + "a", CidrBlock='10.0.1.0/24', VpcId=resourcesCreated['vpc'])
        resourcesCreated['publicSubnet'] = response['Subnet']['SubnetId']
        time.sleep(5)

        # Tag the resource so we can filter on it later
        response = client.create_tags(Resources=[resourcesCreated['publicSubnet']], Tags=[{'Key': 'Name', 'Value': str(name) + "-PublicSubnet"}])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Third create the Private Subnets
    availabilityZones = []
    try:
        regionInfo = client.describe_availability_zones(Filters=[{'Name': 'region-name', 'Values': [str(region)]}])
        for az in regionInfo['AvailabilityZones']:
            if az['ZoneName'] not in availabilityZones:
                availabilityZones.append(az['ZoneName'])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create a private subnet for each AZ so that we can choose which one to launch the instances into
    resourcesCreated['privateSubnets'] = []
    cidrNumber = 2
    print("Creating the Private Subnets.")
    for az in availabilityZones:
        try:
            response = client.create_subnet(AvailabilityZone=az, CidrBlock='10.0.' + str(cidrNumber) + '.0/24', VpcId=resourcesCreated['vpc'])
            resourcesCreated['privateSubnets'].append({"az": az, "subnetId": response['Subnet']['SubnetId']})
            time.sleep(5)

            # Tag the resource so we can filter on it later
            response = client.create_tags(Resources=[response['Subnet']['SubnetId']], Tags=[{'Key': 'Name', 'Value': str(name) + "-PrivateSubnet-" + str(az)}])
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}
        cidrNumber += 1

    # Need to create an InternetGateway so that the bastion host can talk to the Internet
    try:
        print("Creating the Internet Gateway.")
        response = client.create_internet_gateway()
        resourcesCreated['internetGateway'] = response['InternetGateway']['InternetGatewayId']
        time.sleep(5)

        # Tag the resource so we can filter on it later
        response = client.create_tags(Resources=[resourcesCreated['internetGateway']], Tags=[{'Key': 'Name', 'Value': str(name) + "-InternetGateway"}])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # After creation need to attach the Internet Gateway to VPC
    try:
        print("Attaching the Internet Gateway.")
        # Wait for the resource creation to complete
        time.sleep(30)

        response = client.attach_internet_gateway(InternetGatewayId=resourcesCreated['internetGateway'], VpcId=resourcesCreated['vpc'])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create Route to Internet Gateway
    try:
        print("Creating Route to the Internet Gateway.")
        # Wait for the resource creation to complete
        time.sleep(30)

        res = client.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [resourcesCreated['vpc']]}])
        routeTableId = res['RouteTables'][0]['RouteTableId']

        response = client.create_route(GatewayId=resourcesCreated['internetGateway'], RouteTableId=routeTableId, DestinationCidrBlock="0.0.0.0/0")
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create a Public Security Group to be used by the Bastion host to allow SSH
    try:
        print("Creating the Public Security Group.")
        response = client.create_security_group(Description='Allow public SSH access to the bastion host for the experiment: ' + str(name), GroupName=str(name) + "-Public-SecurityGroup", VpcId=resourcesCreated['vpc'])
        resourcesCreated['publicSecurityGroup'] = response['GroupId']
        time.sleep(5)

        # Tag the resource so we can filter on it later
        response = client.create_tags(Resources=[resourcesCreated['publicSecurityGroup']], Tags=[{'Key': 'Name', 'Value': str(name) + "-PublicSecurityGroup"}])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create the Security Group Rules for the previously created Public Security Group
    try:
        print("Adding the rules for the Public Securiy Group.")
        # Wait for the resource creation to complete
        time.sleep(10)

        listOfPermissionsToAdd = [{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": '0.0.0.0/0'}]}, {"IpProtocol": "-1", "IpRanges": [{"CidrIp": '10.0.0.0/16'}]}]
        response = client.authorize_security_group_ingress(GroupId=resourcesCreated['publicSecurityGroup'], IpPermissions=listOfPermissionsToAdd)
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create a Private Security Group to be used by the internal instances that will allow all traffic from any instance in the VPC
    try:
        print("Creating the Private Security Group.")
        response = client.create_security_group(Description='Allows all of the internal instances to accept traffic from any IP within the VPC for the experiment: ' + str(name), GroupName=str(name) + "-Private-SecurityGroup", VpcId=resourcesCreated['vpc'])
        resourcesCreated['privateSecurityGroup'] = response['GroupId']
        time.sleep(5)

        # Tag the resource so we can filter on it later
        response = client.create_tags(Resources=[resourcesCreated['privateSecurityGroup']], Tags=[{'Key': 'Name', 'Value': str(name) + "-PrivateSecurityGroup"}])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create the Security Group Rules for the previously created Public Security Group
    try:
        print("Adding the rules for the Private Security Group.")
        # Wait for the resource creation to complete
        time.sleep(10)

        listOfPermissionsToAdd = [{"IpProtocol": "-1", "IpRanges": [{"CidrIp": '10.0.0.0/16'}]}]
        response = client.authorize_security_group_ingress(GroupId=resourcesCreated['privateSecurityGroup'], IpPermissions=listOfPermissionsToAdd)
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create the Route Table that will be used for the NAT Instance
    try:
        print("Creating the Route Table to be used for the NAT process.")

        response = client.create_route_table(VpcId=resourcesCreated['vpc'])
        resourcesCreated['natRouteTable'] = response['RouteTable']['RouteTableId']

        response = client.create_tags(Resources=[resourcesCreated['natRouteTable']], Tags=[{'Key': 'Name', 'Value': str(name) + "-NatRouteTable"}])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create the Subnet Route Table associations required for the use of NAT
    try:
        print("Creating the Subnet/Route Table associations to be used in the NAT Process.")
        time.sleep(10)

        # Loop through the private subnets and associate all of them with the new Route Table
        for subnet in resourcesCreated['privateSubnets']:
            try:
                response = client.associate_route_table(RouteTableId=resourcesCreated['natRouteTable'], SubnetId=subnet['subnetId'])
            except Exception as e:
                 print(''.join(traceback.format_exc()))
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create a NAT instance so that the internal instances can access the Public Internet
    try:
        print("Creating the NAT Instance.")
        # Wait for the resource creation to complete
        time.sleep(10)

        networkInterfaces = [{'AssociatePublicIpAddress': True, 'DeviceIndex': 0, 'SubnetId' : resourcesCreated['publicSubnet'], 'Groups': [resourcesCreated['publicSecurityGroup']]}]

        response = client.run_instances(ImageId=natImage, MinCount=1, MaxCount=1, KeyName=keyName, InstanceType=instanceType, Monitoring={"Enabled": False}, DisableApiTermination=False, InstanceInitiatedShutdownBehavior="stop", Placement={"AvailabilityZone": str(region) + "a"}, NetworkInterfaces=networkInterfaces)
        # Get the instanceId from the response
        for instance in response['Instances']:
            resourcesCreated['natInstance'] = instance['InstanceId']
        time.sleep(5)

        # Wait until the instance is in the Running state
        print("Waiting for the NAT Instance to become ready.")
        waiter = client.get_waiter('instance_running')
        waiter.wait(InstanceIds=[resourcesCreated['natInstance']])

        response = client.create_tags(Resources=[resourcesCreated['natInstance']], Tags=[{'Key': 'Name', 'Value': str(name) + "-NatInstance"}])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Modify the NAT Instance so that the SourceDestCheck attribute is disabled
    try:
        print("Setting the SourceDestCheck attribute to False on the NAT Instance.")

        response = client.modify_instance_attribute(SourceDestCheck={'Value': False}, InstanceId=resourcesCreated['natInstance'])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create the route for the Route Table to route all internal outbound traffic to the NAT instance
    try:
        print("Creating Route to the NAT Instance")
        # Wait for the resource creation to complete
        time.sleep(10)

        response = client.create_route(InstanceId=resourcesCreated['natInstance'], RouteTableId=resourcesCreated['natRouteTable'], DestinationCidrBlock="0.0.0.0/0")
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    # Create the bastion host that will allow us to SSH into the private instances
    try:
        print("Creating the Bastion Host.")
        # Wait for the resource creation to complete
        time.sleep(10)

        networkInterfaces = [{'AssociatePublicIpAddress': True, 'DeviceIndex': 0, 'SubnetId' : resourcesCreated['publicSubnet'], 'Groups': [resourcesCreated['publicSecurityGroup']]}]

        response = client.run_instances(ImageId=imageId, MinCount=1, MaxCount=1, KeyName=keyName, InstanceType=instanceType, Monitoring={"Enabled": False}, DisableApiTermination=False, InstanceInitiatedShutdownBehavior="stop", Placement={"AvailabilityZone": str(region) + "a"}, NetworkInterfaces=networkInterfaces)
        # Get the instanceId from the response
        for instance in response['Instances']:
            resourcesCreated['bastionHost'] = instance['InstanceId']
        time.sleep(5)

        # Wait until the instance is in the Running state
        print("Waiting for the Bastion Host to become ready.")
        waiter = client.get_waiter('instance_running')
        waiter.wait(InstanceIds=[resourcesCreated['bastionHost']])

        response = client.create_tags(Resources=[resourcesCreated['bastionHost']], Tags=[{'Key': 'Name', 'Value': str(name) + "-BastionHost"}])
    except Exception as e:
        return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesCreated": resourcesCreated}}

    return {"status": "success", "payload": {"resourcesCreated": resourcesCreated}}

def createGcpResources(service, name):
    pass

def deleteAwsResources(client, name):
    resourcesToDelete = None

    # Load the resources to delete from the file written out by the create function
    with open(thisDir + "/networkResourcesCreated-" + str(name) + ".json") as outputFile:
        resourcesToDelete = json.load(outputFile)

    # Delete the Bastion Host
    if 'bastionHost' in resourcesToDelete:
        try:
            print("Deleting the Bastion Host.")
            response = client.terminate_instances(InstanceIds=[resourcesToDelete['bastionHost']])

            # Wait until the instance is in the Terminate state
            print("Waiting for the Bastion Host to terminate.")
            waiter = client.get_waiter('instance_terminated')
            waiter.wait(InstanceIds=[resourcesToDelete['bastionHost']])
            del resourcesToDelete['bastionHost']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    if 'natInstance' in resourcesToDelete:
        try:
            print("Deleting the NAT Instance.")
            response = client.terminate_instances(InstanceIds=[resourcesToDelete['natInstance']])

            # Wait until the instance is in the Terminate state
            print("Waiting for the NAT Instance to terminate.")
            waiter = client.get_waiter('instance_terminated')
            waiter.wait(InstanceIds=[resourcesToDelete['natInstance']])
            del resourcesToDelete['natInstance']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    # Delete the Private Security Group
    if 'privateSecurityGroup' in resourcesToDelete:
        try:
            print("Deleting the Private Security Group.")
            response = client.delete_security_group(GroupId=resourcesToDelete['privateSecurityGroup'])
            del resourcesToDelete['privateSecurityGroup']
            time.sleep(5)
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    # Delete the Public Security Group
    if 'publicSecurityGroup' in resourcesToDelete:
        try:
            print("Deleting the Public Security Group.")
            response = client.delete_security_group(GroupId=resourcesToDelete['publicSecurityGroup'])
            del resourcesToDelete['publicSecurityGroup']
            time.sleep(5)
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    # Detach the Internet Gateway from the VPC
    if 'internetGateway' in resourcesToDelete:
        try:
            print("Detaching the Internet Gateway.")

            response = client.detach_internet_gateway(InternetGatewayId=resourcesToDelete['internetGateway'], VpcId=resourcesToDelete['vpc'])
            # Wait for the resource detachment to complete
            time.sleep(15)
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    # Delete the InternetGateway
    if 'internetGateway' in resourcesToDelete:
        try:
            print("Deleting the Internet Gateway.")
            response = client.delete_internet_gateway(InternetGatewayId=resourcesToDelete['internetGateway'])
            del resourcesToDelete['internetGateway']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    # Delete the private subnets
    if 'privateSubnets' in resourcesToDelete:
        try:
            print("Deleting the Private Subnets.")
            import copy
            subnetList = copy.deepcopy(resourcesToDelete['privateSubnets'])
            for subnet in subnetList:
                try:
                    response = client.delete_subnet(SubnetId=subnet['subnetId'])
                    resourcesToDelete['privateSubnets'].remove(subnet)
                except Exception:
                    print(''.join(traceback.format_exc()))
            if len(resourcesToDelete['privateSubnets']) == 0:
                del resourcesToDelete['privateSubnets']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    # Delete the Public subnet
    if 'publicSubnet' in resourcesToDelete:
        try:
            print("Deleting the Public Subnet.")

            response = client.delete_subnet(SubnetId=resourcesToDelete['publicSubnet'])
            del resourcesToDelete['publicSubnet']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}
    
    if 'natRouteTable' in resourcesToDelete:
        try:
            print("Deleting the NAT Route Table.")

            response = client.delete_route_table(RouteTableId=resourcesToDelete['natRouteTable'])
            del resourcesToDelete['natRouteTable']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

     # Delete the VPC
    if 'vpc' in resourcesToDelete:
        try:
            print("Deleting the VPC.")
            response = client.delete_vpc(VpcId=resourcesToDelete['vpc'])
            del resourcesToDelete['vpc']
        except Exception as e:
            return {"status": "error", "message": ''.join(traceback.format_exc()), "payload": {"resourcesToDelete": resourcesToDelete}}

    if len(resourcesToDelete) == 0:
        return {"status": "success", "message": "The resources have been successfully deleted", "payload": None}
    else:
        return {"status": "error", "message": "There was an issue deleting some of the resources", "payload": resourcesToDelete}

def deleteGcpResources(service, name):
    pass

def dumpResourcesCreatedToFile(resourcesCreated, name):
    with open(thisDir + "/networkResourcesCreated-" + str(name) + ".json", "w") as outputFile:
        json.dump(resourcesCreated, outputFile, sort_keys=True, indent=4, separators=(',', ': '))

main()
