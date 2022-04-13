# Deploy _Jump App_ Solution (Internal HTTP connectivity)

In order to test the global solution including external HTTPs accesses and internal HTTP connections, it is required to deploy an application and integrate it into the service mesh first.

The following procedures and sections try to deploy _Jump App_ in the application namespace and control ingress and egress traffic through the respective control planes.

## Deploy _Jump App_ and Configure Internal Traffic 

During this section, the application will be deployed and the mesh configured in order to allow internal traffic.

Execute the following procedure to deploy this application and configure all service mesh objects to be able external traffic and internal traffic work correctly.

- Include the required domain for deploying _Jump App_

```$bash
sed 's/apps.test.sandbox1196.opentlc.com/<openshift_apps_domain>/g' -i resources/control_planes/workload/jump-app-http.yaml
```

- Deploy _Jump App_ in the respective namespace

```$bash
oc apply -f resources/control_planes/workload/jump-app-http.yaml
```

- Verify objects created in Openshift

```$bash
oc get all -n jump-app-dev
NAME                                       READY   STATUS    RESTARTS   AGE
pod/back-golang-v1-6d57d5cc57-rpwcq        2/2     Running   0          48s
pod/back-python-v1-76fd9495c5-kcffs        2/2     Running   0          48s
pod/back-quarkus-v1-75d65c4b7f-wzdsc       2/2     Running   0          47s
pod/back-springboot-v1-5f6cc67c8f-v44wq    2/2     Running   0          47s
pod/front-javascript-v1-5bf77b8899-s7d6t   2/2     Running   0          47s
...
```

- Test application deployed

```$bash
oc exec back-golang-v1-6d57d5cc57-rpwcq -c back-golang-v1 -- curl -H "Content-type: application/json" -d '{
    "message": "Hello",
    "last_path": "/jump",
    "jump_path": "/jump",
    "jumps": [
        "http://back-golang:8442",
        "http://back-springboot:8443",
        "http://back-python:8444",
        "http://back-quarkus:8445"
    ]
}' 'localhost:8442/jump'

....
{"code":200,"message":"/jump - Greetings from Quarkus!"}

```

## Configure Ingress Traffic

Once the application is deployed and the internal traffic works, it is time to allow external access to the application configuring the ingress control plane. 

Execute the following procedure to configure the required objects in the ingress control plane namespace.

- Include the required domain for deploying _Jump App_

```$bash
sed 's/apps.test.sandbox1196.opentlc.com/<openshift_apps_domain>/g' -i resources/control_planes/ingress/jump-app-http.yaml
```

- Deploy _Jump App_ ingress objects

```$bash
oc apply -f resources/control_planes/ingress/jump-app-http.yaml
```

- Test _Jump App_ application external traffic

```$bash
curl -H "Content-type: application/json" -d '{
    "message": "Hello",
    "last_path": "/jump",
    "jump_path": "/jump",
    "jumps": [
        "http://back-golang:8442",
        "http://back-springboot:8443",
        "http://back-python:8444",
        "http://back-quarkus:8445"
    ]
}' https://back-golang-jump-app-dev.apps.test.sandbox1196.opentlc.com/jump -k

....
{"code":200,"message":"/jump - Greetings from Quarkus!"}
```

NOTE: It is required to specify the Openshift application domain correctly in the example command

If the final test is ok, an application is deployed with traffic flow configured between multiples control planes through multiple namespaces (mesh_ingress -> mesh_workload -> jump-app-dev)

## Configure Egress Traffic

So far, external connections are allowed in order to access _Jump App_ services. By contrast, it is not possible to access from _Jump App_ microservices to the external world.

In order to test the previous asumption, execute the following command:

```$bash
oc exec back-golang-v1-6d57d5cc57-rpwcq -c back-golang-v1 -- curl www.google.com -v

...
< HTTP/1.1 502 Bad Gateway
...
* Connection #0 to host www.google.com left intact
```

In order to allow this external traffic through the respective egress control plane, it is required to execute the following procedure.

- Configure workloads to flow the external traffic through the respect egress solution

```$bash
oc apply -f resources/control_planes/workload/jump-app-http-egress.yaml 
```

- It is important to keep in mind that external access traffic is redirected to the egress control plane thanks to the previous objects created but the external access still does not work 

```$bash
oc exec back-golang-v1-6d57d5cc57-rpwcq -c back-golang-v1 -- curl www.google.com -v
...
< HTTP/1.1 503 Service Unavailable
...
upstream connect error or disconnect/reset before headers. reset reason: connection failure
```

- Configure egress objects to allow external traffic and route it correctly

```$bash
oc apply -f resources/control_planes/egress/jump-app-http.yaml
```

- Test the external access

```$bash
oc exec back-golang-v1-6d57d5cc57-rpwcq -c back-golang-v1 -- curl www.google.com -v

...
< HTTP/1.1 200 OK
...
```

## Author

Asier Cidon @RedHat
