##AFCloudFilesClient

AFCloudFilesClient is an add-on to AFNetworking to support network interaction with the Rackspace Cloud Files service.

This first version is just a quick-hack to facilitate image uploads to Cloud Files for a project I'm working on at the moment.

**Updated**: 

 - Merged the authenticate method into the initializer.
 - Added a **retrieveImageWithFilename:fromContainer:** method that returns the image via a delegate method.

**Instructions**:

 - Create a **AFCloudFilesClient** object. It will authenticate during init.
 - Call for the relevant method required. Currently available are **uploadFileToContainer:withFilename:data:andContentType:** and **retrieveImageWithFilename:fromContainer:**
 - Proceed with the relevant delegates for those methods.

**Things to come**:

- Integrating authentication within the client so that explicit calls will not be necessary.
- Turning the AFCloudFilesClient into a singleton client class method so it can be called directly without needing to instantiate a new object.