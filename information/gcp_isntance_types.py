# export GOOGLE_APPLICATION_CREDENTIALS="/Users/ben/Documents/gcp-performance-3715cbdeba57.json"

from pprint import pprint

from googleapiclient import discovery
from oauth2client.client import GoogleCredentials

credentials = GoogleCredentials.get_application_default()

service = discovery.build('compute', 'v1', credentials=credentials)

# Project ID for this request.
project = 'gcp-performance'  # TODO: Update placeholder value.

request = service.regions().list(project=project)
while request is not None:
    response = request.execute()

    for region in response['items']:
        # TODO: Change code below to process each `region` resource:
        pprint(region)

    request = service.regions().list_next(previous_request=request, previous_response=response)
