# Horizon Motion Service

Provide motion-project.io service

## Input Values

This service takes no input values.

## RESTful API

Other Horizon services can use the CPU Percent service by requiring it in its own service definition, and then in its code accessing the CPU Percent REST APIs with the URL:
```
http://motion:7999/cgi-bin/
```

### **API:** GET /motion-index.cgi
---

#### Parameters:
some

#### Response:

code: 
* 200 -- success
* other http codes TBD

body:


| Name | Type | Description |
| ---- | ---- | ---------------- |
| motion | float | the motion percent currently being used on this edge node host |


#### Example:
```
curl -sS -w "%{http_code}" http://motion:8347/v1/motion | jq .
{
  "motion": 5.05
}
200
```
