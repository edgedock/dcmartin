# Horizon Hardware Abstraction Layer service

Provide CPU processor info encoded as JSON

## Input Values

This service takes no input values.

## RESTful API

Other Horizon services can use the `cpu` service by requiring it in its own service definition.

### **API:** 

```
http://cpu:80/
```
---

#### Parameters:

None

#### Response:

```
{
}
```

#### Example:

```
% curl
{
}
```
