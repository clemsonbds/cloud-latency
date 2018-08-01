This Python script will create and delete all of the required AWS Network resources as well as the Bastion host that we can use to SSH into the nodes in the private subnets. The way this works is based off of the "name" parameter passed to the script. To delete the resources associated with a certain "name" just change the create flag to delete and it will automatically delete the appropriate resources.

Use both of these scripts to setup the infrastructure required for testing your scripts. We will have to make some adjustments to pass the UserData to the instances to automate the startup process but it shouldn't be too hard.
You will need to create AWS Access Keys and have the pip package botocore installed in order to run the script, I tried to put in helpful error messages if these packages/credentials weren't found.

After you have done that you can execute the two scripts. I have included a sample execution below which will creae the network/bastion host and launch 2 instances in the same AZ:

```
python createNetworkBastionHost.py --create --region us-east-1 --name testing --keyName somekeypair
python launchInstances.py --create --region us-east-1 --name testing --keyName somekeypair --azs a --experimentType single-az
```

For the launchInstances.py script there are 3 different experiment types: single-az, multi-az, and placementGroup. Single-az launches the number of requested instances within a single AZ, multi-az attempts to spread out the instances over the AZs specified, and placementGroup attempts to launch the instances in a single AZ and inside a Placement Group.

To delete you can run the following commands:

```
python launchInstances.py --delete --region us-east-1 --name testing --keyName somekeypair --azs a
python createNetworkBastionHost.py --delete --region us-east-1 --name testing --keyName somekeypair
```

The command to get the IP addresses of all the instances running for the particular experiment is:

```
aws ec2 --region us-east-1 describe-instances --filters "Name=tag:Name,Values=testing-Instance" "Name=instance-state-name,Values=running" | grep PrivateIpAddress\" | awk '{$1=$1};1' | cut -d'"' -s -f4 | sort -u
```

That will output the IPs in the following format:

```
10.0.2.28
10.0.3.141
```
