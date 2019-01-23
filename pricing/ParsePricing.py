#Copyright Omnibond Systems, LLC. All rights reserved.
#
#Terms of Service are located at:
#http://www.cloudycluster.com/termsofservice

import traceback
import urllib2
import json
import sys

# takes in 2 command line parameters the first being the name of the instance and the second being the region
# If you do not give a region then the program will default to us-east-1
def parseEC2Pricing():

    region = "us-east-1"
    if len(sys.argv) > 2:
        region = sys.argv[2]
    instanceList = json.loads(urllib2.urlopen("https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonEC2/current/" + str(region) + "/index.json").read())


    instance = sys.argv[1]


    pricingObj = instanceList['terms']['OnDemand']
    try:
        for key in pricingObj:
            myList = pricingObj[key]
            bois = myList[myList.keys()[0]]['priceDimensions']
            if instance in bois[bois.keys()[0]]['description']:
                pricingObj = instanceList['terms']['OnDemand'][key]
                break



        for item in pricingObj:
            price = pricingObj[item]['priceDimensions']
            pricePH = price[price.keys()[0]]['pricePerUnit']['USD']
            if float(pricePH) <= 0:
                print("Could not find price for " + instance + " in " + region)
            else:
                print("Price for " + instance + " in " + region + " is: $" + pricePH + " per hour")
            return
    except:
            print("Could not find price for " + instance + " in " + region)


def main():
    parseEC2Pricing()

main()
