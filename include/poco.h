#ifndef _CHERRY_POCO_H
#define _CHERRY_POCO_H

#include <string>
#include <vector>
#include <unordered_map>
#include <iostream>
#include <Poco/Net/ServerSocket.h>
#include <Poco/Net/HTTPServer.h>
#include <Poco/Net/HTTPRequestHandler.h>
#include <Poco/Net/HTTPRequestHandlerFactory.h>
#include <Poco/Net/HTTPResponse.h>
#include <Poco/Net/WebSocket.h>
#include <Poco/Net/HTTPServerRequest.h>
#include <Poco/Net/HTTPServerResponse.h>
#include <Poco/Net/DatagramSocket.h>
#include <Poco/Util/ServerApplication.h>
#include <Poco/Net/MulticastSocket.h>
#include <Poco/TaskManager.h>
#include <Poco/Net/NetException.h>
#include "net.h"

namespace poco
{

#define PN Poco::Net

    class WebSocket : public net::WebSocket
    {
    public:
        WebSocket(PN::WebSocket &ws) : PN_ws(&ws) {}
        int receive(void *buffer, int length);
        void send(void *buffer, int length);

    private:
        PN::WebSocket *PN_ws = 0;
    };

    class HttpRequest : public net::HttpRequest
    {
    public:
        HttpRequest() : PN_req(NULL) {}
        HttpRequest(PN::HTTPRequest *req) : PN_req(req), ibody(0) {}
        HttpRequest(PN::HTTPRequest *req, std::istream *ibody) : PN_req(req), ibody(ibody) {}
        PN::HTTPRequest *toPNRequest();
        void fromPNRequest(PN::HTTPRequest *req);

        std::istream &getBody();
        std::ostream &setBody();

        std::string getMethod();
        void setMethod(std::string method);

        std::string getPath();
        void setPath(std::string path);

        std::string getHeader(std::string key);
        net::dict *getAllHeaders();
        void setHeader(std::string key, std::string value);

        bool canUpgradeToWs();
        WebSocket *upgrade();

        PN::HTTPServerRequest *pn_serv_req = 0;
        PN::HTTPServerResponse *pn_serv_res = 0;

    private:
        PN::HTTPRequest *PN_req;
        std::istream *ibody;
    };

    class HttpResponse : public net::HttpResponse
    {
    public:
        HttpResponse() : PN_res(NULL) {}
        HttpResponse(PN::HTTPResponse *res) : PN_res(res), obody(0) {}
        HttpResponse(PN::HTTPResponse *res, std::ostream *obody) : PN_res(res), obody(obody) {}
        PN::HTTPResponse *toPNResponse();
        void fromPNResponse(PN::HTTPResponse *res);

        std::istream &getBody();
        std::ostream &setBody();

        int getStatus();
        std::string getStatusText();
        void setStatus(int code, std::string text);

        std::string getHeader(std::string key);
        net::dict *getAllHeaders();
        void setHeader(std::string key, std::string value);

    private:
        PN::HTTPResponse *PN_res;
        std::ostream *obody;
    };

    class HttpReqHandeler : public net::HttpReqHandeler
    {
    public:
        HttpReqHandeler();
        virtual void handle(HttpRequest *req, HttpResponse *res);
    };

    class HttpReqHandlerFactory : public net::HttpReqHandlerFactory
    {
    public:
        virtual HttpReqHandeler *create();
    };

    class HttpServer : public net::HttpServer
    {
        net::SocketAddress addr;
        PN::HTTPServer *server;

    public:
        HttpServer(int port, HttpReqHandlerFactory *reqHandlerFactory);
    };

    class NetworkStack : public net::NetworkStack
    {
    public:
        virtual HttpServer *CreateHttpServer();
    };

}

#endif