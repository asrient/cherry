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
#include <Poco/Net/NetException.h>
#include "../include/poco.h"
#include "../include/net.h"

using namespace poco;

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