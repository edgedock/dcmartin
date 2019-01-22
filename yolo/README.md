# YOLO service

Provide YOLO as-a-service response as JSON

## Input Values

This service takes no input values.

## RESTful API

Other Horizon services can use the `yolo` service by requiring it in its own service definition.

### **API:** 

```
http://yolo:8585/
```
---

#### Response:

```
{
 "devid": "test-yolo-1",
 "seen": [ { "entity": "human", "count": 1 } ],
 "date": 32767,
 "period": 5
}
```
