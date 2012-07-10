AFCloudFilesClient ==================

AFNetworking Client for Rackspace Cloud Files.

This first version is just a quick-hack to facilitate image uploads to Cloud Files for a project I'm working on at the moment.

Create a client, call the authenticate method, and do your uploading within the authentication successful delegate method. Right now there's only one method, will include more along the way when I have time to add additional features.

Would like to set it up as a singleton client as well, similar to the ASIHTTPRequest Cloud Files client I was using before I switched to AFNetworking.