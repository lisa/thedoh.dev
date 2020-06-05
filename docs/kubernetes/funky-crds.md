---
title: Funky CRDs
parentcategory: "kubernetes"
category: funky-crds
description: |
  Sometimes there are funky interactions with CustomResourceDefinitions.
---

# Funky CRDs

This week I ran into a pretty weird bug that mashed up a confluence of a number of things:

* Code changes
* Separate, but related project that generates YAML (sigh, yaml)
* JSON marshalling in Go
* Kubernetes CRDs

How these all intertwine centres around the Kubernetes CRD and JSON marshalling.

Say you have a CRD and its API is:

```go
type Funky struct {
	Spec FunkySpec `json:"spec,omitempty"`
}

type FunkySpec struct {
	Enabled bool `json:"enabled"
}
```

This means that you have a `Spec` of type `FunkySpec` and in JSON (and YAML, for "reasons") it is referred to by `spec` and people don't have to provide it.

When it's empty it tells Go not to freak out and to provide the default values for a new `FunkySpec{}`. Standard Go stuff here.

Where it gets funky is custom controllers are necessarily tightly coupled to the API, so when in a `Funky` controller it will want to do something with a `Funky` object and access the `Spec` of that object to see what the controller should do.

What happens when your controller tries to access a `Spec` that isn't there? It uses the default values, of course! That's what you want, with `omitempty`. It's how you let users not have to define every attribute (looking at you, `DeploymentSpec`). But what if the entire object is optional, by mistake? (How would that even happen? Stay tuned.)

A coworker introduced new automation designed to generate YAML (sigh, YAML) and it should create a `Funky` object with its `FunkySpec`. Well... in the Python generation code the coworker missed a couple indented spaces. (oops, no strict type checking!) and so the resulting YAML was completely valid YAML, but not a well-formed `Funky` object, or so you'd think.

By coincidence, I had code that consumed the `Funky` objects and it happened to be changing in a fundamental way. I referenced a boolean in `FunkySpec` and marked reconcilation of the `Funky` as complete based on it. What's the default value in Go for a boolean inside a struct? It is `false`. So, I was consuming `Funky` objects that had weird defaults because the Kubernetes API will happily accept a Funky object, and feed it to a watch handler when it's not quite right.

Once my coworker introduced their change, the `Funky` object I cared about changed but it lacked a `Spec`. Due to the nature of the development pattern there was also a race condition at play ([it's complicated](https://github.com/openshift/hive]) because there were two authoritative sources of that `Funky` object! When I was testing my code I never hit the failure side of the race condition by some happenstance, but most of my coworkers did.

The manifestation of this problem was that my code change had broke something in a fundamentally weird way. Tracing through the code (devoid of log messages because it would otherwise be _very_ chatty) pointed to one possible place it could be be failing in this way, but it should never come up because that boolean _IS_ always `true` - the `if !true` code path should never be reached!

Except when there's no `FunkySpec` because the YAML (sigh, YAML) was indented incorrectly, because I never took away the `omitempty` generated code in the operator I was working with, because why would it matter? We'll always set it.

## Reproduction

If you'd like to reproduce this yourself, here is the CRD:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: funkies.k8s.thedoh.dev
spec:
  group: k8s.thedoh.dev
  names:
    kind: Funky
    listKind: FunkyList
    plural: funkies
    singular: funky
  scope: Namespaced
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        description: Funky is the Schema for the funkies API
        properties:
          apiVersion:
            description: 'APIVersion defines the versioned schema of this representation
              of an object. Servers should convert recognized schemas to the latest
              internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources'
            type: string
          kind:
            description: 'Kind is a string value representing the REST resource this
              object represents. Servers may infer this from the endpoint the client
              submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds'
            type: string
          metadata:
            type: object
          spec:
            description: FunkySpec defines the desired state of Funky
            properties:
              importantInfo:
                properties:
                  enabled:
                    type: boolean
                  name:
                    type: string
                  purpose:
                    type: string
                required:
                - enabled
                - name
                - purpose
                type: object
            required:
            - importantInfo
            type: object
          status:
            description: FunkyStatus defines the observed state of Funky
            properties:
              ready:
                type: boolean
            required:
            - ready
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
```

Applying an instance of this to [in my lab cluster](/kubernetes/rock64-cluster.html):

```yaml
# deploy/crds/k8s.thedoh.dev_v1alpha1_funky_cr.yaml
apiVersion: k8s.thedoh.dev/v1alpha1
kind: Funky
metadata:
  name: example-funky
importantInfo:
  name: funky
  purpose: confusion
  enabled: true
```

```shell
# kubectl -n funky apply -f deploy/crds/k8s.thedoh.dev_v1alpha1_funky_cr.yaml
funky.k8s.thedoh.dev/example-funky created
```

Let's read it back from the cluster:

```yaml
# (⎈ |kubernetes-admin@kubernetes:default)lisa@cadmium k8s-funky-crds $ kubectl -n funky get funky example-funky -o yaml
apiVersion: k8s.thedoh.dev/v1alpha1
importantInfo:
  enabled: true
  name: funky
  purpose: confusion
kind: Funky
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"k8s.thedoh.dev/v1alpha1","importantInfo":{"enabled":true,"name":"funky","purpose":"confusion"},"kind":"Funky","metadata":{"annotations":{},"name":"example-funky","namespace":"funky"}}
  creationTimestamp: "2020-06-05T01:39:06Z"
  generation: 1
  managedFields:
  - apiVersion: k8s.thedoh.dev/v1alpha1
    fieldsType: FieldsV1
    fieldsV1:
      f:importantInfo:
        .: {}
        f:enabled: {}
        f:name: {}
        f:purpose: {}
      f:metadata:
        f:annotations:
          .: {}
          f:kubectl.kubernetes.io/last-applied-configuration: {}
    manager: oc
    operation: Update
    time: "2020-06-05T01:39:06Z"
  name: example-funky
  namespace: funky
  resourceVersion: "70178603"
  selfLink: /apis/k8s.thedoh.dev/v1alpha1/namespaces/funky/funkies/example-funky
  uid: 0c1fd3b1-6e07-4e9b-8c2f-3e66c951d61e
```

This was a very odd bug to uncover due to all of the concurrent factors: Code changes in two places, unexpected behaviour with the Go code, no insight into why the CR was reconciling with a "NOOP".
