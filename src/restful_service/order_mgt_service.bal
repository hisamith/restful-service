package restful_service;

import ballerina/http;
//import ballerinax/docker;
//import ballerinax/kubernetes;

endpoint http:ServiceEndpoint orderMgtServiceEP {
    port:9090
};

//@docker:Config {
//    registry:"ballerina.guides.io",
//    name:"restful_service",
//    tag:"v1.0"
//}

//@kubernetes:SVC {
//    serviceType:"NodePort",
//    name:"ballerina-guides-restful-service"
//}

//@kubernetes:Deployment {
//    image: "ballerinaguides/ballerina-guides-restful-service",
//    env:"SIDECAR_HTTP_PORT:9090, SERVICE_PORT:8080",
//    name: "ballerina-guides-restful-service"
//}
//
//@kubernetes:Ingress {
//    hostname:"ballerina.guides.io",
//    name:"ballerina-guides-restful-service",
//    path:"/"
//}


// Order management is done using an in memory orders map.
// Add some sample orders to the orderMap during the startup.
map<json> ordersMap = {};

@Description {value:"RESTful service."}
@http:ServiceConfig {basePath:"/ordermgt"}
service<http:Service> OrderMgtService bind orderMgtServiceEP {

    @Description {value:"Resource that handles the HTTP GET requests that are directed to a specific order using path '/orders/<orderID>'"}
    @http:ResourceConfig {
        methods:["GET"],
        path:"/order/{orderId}"
    }
    findOrder (endpoint client, http:Request req, string orderId) {
        // Find the requested order from the map and retrieve it in JSON format.
        json payload = ordersMap[orderId];
        http:Response response = {};
        if (payload == null) {
            payload = "Order : " + orderId + " cannot be found.";
        }

        // Set the JSON payload to the outgoing response message to the client.
        response.setJsonPayload(payload);

        // Send response to the client
        _ = client -> respond(response);
    }

    @Description {value:"Resource that handles the HTTP POST requests that are directed to the path '/orders' to create a new Order."}
    @http:ResourceConfig {
        methods:["POST"],
        path:"/order"
    }
    addOrder (endpoint client, http:Request req) {
        json orderReq =? req.getJsonPayload();
        string orderId = orderReq.Order.ID.toString();
        ordersMap[orderId] = orderReq;

        // Create response message
        json payload = {status:"Order Created.", orderId:orderId};
        http:Response response = {};
        response.setJsonPayload(payload);

        // Set 201 Created status code in the response message
        response.statusCode = 201;
        // Set 'Location' header in the response message. This can be used by the client to locate the newly added order.
        response.setHeader("Location", "http://localhost:9090/ordermgt/order/" + orderId);

        // Send response to the client
        _ = client -> respond(response);
    }

    @Description {value:"Resource that handles the HTTP PUT requests that are directed to the path '/orders' to update an existing Order."}
    @http:ResourceConfig {
        methods:["PUT"],
        path:"/order/{orderId}"
    }
    updateOrder (endpoint client, http:Request req, string orderId) {
        json updatedOrder =? req.getJsonPayload();

        // Find the order that needs to be updated from the map and retrieve it in JSON format.
        json existingOrder = ordersMap[orderId];

        // Updating existing order with the attributes of the updated order
        if (existingOrder != null) {
            existingOrder.Order.Name = updatedOrder.Order.Name;
            existingOrder.Order.Description = updatedOrder.Order.Description;
            ordersMap[orderId] = existingOrder;
        } else {
            existingOrder = "Order : " + orderId + " cannot be found.";
        }

        http:Response response = {};
        // Set the JSON payload to the outgoing response message to the client.
        response.setJsonPayload(existingOrder);
        // Send response to the client
        _ = client -> forward(response);
    }

    @Description {value:"Resource that handles the HTTP DELETE requests that are directed to the path '/orders/<orderId>' to delete an existing Order."}
    @http:ResourceConfig {
        methods:["DELETE"],
        path:"/order/{orderId}"
    }
    cancelOrder (endpoint client, http:Request req, string orderId) {
        http:Response response = {};
        // Remove the requested order from the map.
        _ = ordersMap.remove(orderId);

        json payload = "Order : " + orderId + " removed.";
        // Set a generated payload with order status.
        response.setJsonPayload(payload);

        // Send response to the client
        _ = client -> respond(response);
    }

}
