AFCloudFilesClient

AFCloudFilesClient is an add-on to AFNetworking to support network interaction with the Rackspace Cloud Files service.

This first version is just a quick-hack to facilitate image uploads to Cloud Files for a project I'm working on at the moment.

Set your view controller to be an AFCloudFilesClientDelegate.
Create a client, setDelegate.
Call the authenticate method.
Call the uploadFileToContainer:withFilename:data:andContentType method from within the authentication successful delegate method.

Things to come:
Integrating authentication within the client so that explicit calls will not be necessary.
Turning the AFCloudFilesClient into a singleton client class method so it can be called directly without needing to instantiate a new object, or require delegate methods. Perhaps using blocks?