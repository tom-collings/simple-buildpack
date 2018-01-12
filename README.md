# simple-buildpack
A simple buildpack for multi-buildpack testing.

This buildpack will introspect bound services and if the service contains a credential parameter/value

includeInResources = true

Then this buildpack will add a node to the resoures.xml file (found in APP_DIR/WEB-INF/) based on the other parameters in that bound service.

For the parameters in the following list:

['id', 'type', 'class-name', 'provider', 'factory-name', 'properties-provider', 'classpath', 'aliases', 'post-construct', 'pre-destroy', 'Lazy']

These will be added as attributes to the `resource` node.  Any other parameter will be added as a property to the text value of that `resource` node.

As an example, suppose you have the following bound service:

```json
{
    "credentials": {
     "class-name": "org.cloudfoundry.test.MyType",
     "id": "someId",
     "includeInResources": "true",
     "name1": "val1",
     "name2": "val2"
    },
    "label": "user-provided",
    "name": "my-test-resource",
    "syslog_drain_url": "",
    "tags": [],
    "volume_mounts": []
}
```

you will get the following resources.xml:

```xml
<resources>
  <Resource class-name='org.cloudfoundry.test.MyType' id='someId'>
  name1 = val1
  name2 = val2
</Resource>
</resources>
```

This is intended to be used with the multi-buildpack and have the tomee-buildpack run at some point after it in the chain of buildpacks.  
