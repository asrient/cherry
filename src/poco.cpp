#include <iostream>
#include <sstream>
#include <cstring>
#include <iomanip>
#include <string>
#include <unordered_map>
#include <Poco/Net/ServerSocket.h>
#include <Poco/Net/HTTPServer.h>
#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPRequestHandlerFactory.h>
#include <Poco/Net/HTTPResponse.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>
#include <Poco/Net/DatagramSocket.h>
#include <Poco/Util/ServerApplication.h>
#include <Poco/Net/MulticastSocket.h>
#include <Poco/TaskManager.h>
#include <Poco/Net/WebSocket.h>
#include <Poco/Net/NetException.h>
#include "../include/poco.h"
#include "../include/net.h"

using namespace poco;

////////// WebSocket ////////////

int WebSocket::receive(void *buffer, int length){
    int flags;
    return PN_ws->receiveFrame(buffer, length, flags);
}

void WebSocket::send(void *buffer, int length){
    PN_ws->sendFrame(buffer, length);
}

////////// HttpRequest ////////////

void HttpRequest::fromPNRequest(PN::HTTPRequest *req){
PN_req=req;
}

PN::HTTPRequest* HttpRequest::toPNRequest(){
    return PN_req;
}

std::string HttpRequest::getMethod(){
return PN_req->getMethod();
}
void HttpRequest::setMethod(std::string method){
PN_req->setMethod(method);
}

std::istream& HttpRequest::getBody(){
return *ibody;
}

void HttpRequest::setMethod(std::string method){
PN_req->setMethod(method);
}

std::string HttpRequest::getPath(){
return PN_req->getURI();
}
void HttpRequest::setPath(std::string path){
PN_req->setURI(path);
}

std::string HttpRequest::getHeader(std::string key){
return PN_req->get(key);
}

void HttpRequest::setHeader(std::string key, std::string value){
PN_req->set(key,value);
}

net::dict* HttpRequest::getAllHeaders(){
     net::dict* map= new net::dict;
PN::NameValueCollection::ConstIterator i=PN_req->begin();
        while(i!=PN_req->end()){
            (*map)[i->first]=i->second;
          i++;
        }
    return map;
 }

bool HttpRequest::canUpgradeToWs(){
return (PN_req->find("Upgrade") != PN_req->end() && Poco::icompare((*PN_req)["Upgrade"], "websocket") == 0);
}

WebSocket* HttpRequest::upgrade(){
    try	{
PN::WebSocket* pn_ws = new PN::WebSocket(*pn_serv_req, *pn_serv_res);
return new WebSocket(*pn_ws);
    }
    catch(PN::WebSocketException& exc){
        switch (exc.code())
			{
			case PN::WebSocket::WS_ERR_HANDSHAKE_UNSUPPORTED_VERSION:
				pn_serv_res->set("Sec-WebSocket-Version", PN::WebSocket::WEBSOCKET_VERSION);
				// fallthrough
			case PN::WebSocket::WS_ERR_NO_HANDSHAKE:
			case PN::WebSocket::WS_ERR_HANDSHAKE_NO_VERSION:
			case PN::WebSocket::WS_ERR_HANDSHAKE_NO_KEY:
				pn_serv_res->setStatusAndReason(PN::HTTPResponse::HTTP_BAD_REQUEST);
				pn_serv_res->setContentLength(0);
				pn_serv_res->send();
				break;
			}
        return 0;
    }
}

////////// HttpResponse ////////////

void HttpResponse::fromPNResponse(PN::HTTPResponse *res){
PN_res=res;
}

PN::HTTPResponse* HttpResponse::toPNResponse(){
    return PN_res;
}

std::ostream& HttpResponse::setBody(){
return *obody;
}

std::string HttpResponse::getHeader(std::string key){
return PN_res->get(key);
}

void HttpResponse::setHeader(std::string key, std::string value){
PN_res->set(key,value);
}

net::dict* HttpResponse::getAllHeaders(){
     net::dict* map= new net::dict;
PN::NameValueCollection::ConstIterator i=PN_res->begin();
        while(i!=PN_res->end()){
            (*map)[i->first]=i->second;
          i++;
        }
    return map;
 }

////////// HttpServer ////////////

class PN_RequestHandler : public PN::HTTPRequestHandler
{
    HttpReqHandeler* handler;
public:
    PN_RequestHandler(HttpReqHandeler* h):handler(h){ }
    virtual void handleRequest(PN::HTTPServerRequest &req, PN::HTTPServerResponse &resp)
    {
        std::ostream &out = resp.send();
        HttpRequest reqs= HttpRequest(&req,&req.stream());
        reqs.pn_serv_req=&req;
        reqs.pn_serv_res=&resp;
        HttpResponse res=HttpResponse(&resp,&out);
         handler->handle(&reqs,&res);
        //out.flush();
    }

private:
    static int count;
};

class PN_RequestHandlerFactory : public PN::HTTPRequestHandlerFactory
{
    HttpReqHandlerFactory* reqHandlerFactory;
public:
    PN_RequestHandlerFactory(HttpReqHandlerFactory* h):reqHandlerFactory(h){ }
    PN::HTTPRequestHandler *createRequestHandler(const PN::HTTPServerRequest &)
    {
        HttpReqHandeler* handler = reqHandlerFactory->create();
        return new PN_RequestHandler(handler);
    }
};

HttpServer::HttpServer(int port=NULL, HttpReqHandlerFactory* reqHandlerFactory):addr(NULL){
server = new PN::HTTPServer(new PN_RequestHandlerFactory(reqHandlerFactory), PN::ServerSocket(port), new PN::HTTPServerParams);
}

////////// HttpServer ////////////