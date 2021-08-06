#ifndef _CHERRY_NET_H
#define	_CHERRY_NET_H

#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <unordered_map>
#include <iostream>
#ifdef __APPLE__
#include <sys/types.h>
#endif
#include <iomanip>

namespace net{

typedef unsigned char uchar;
typedef unsigned int uint;
typedef unsigned long ulong;
typedef unsigned char byte;
typedef char *buffer;

struct Buffer{
void* ptr;
int len;
};

typedef std::unordered_map<std::string,std::string> dict;

class SocketAddress{
public:
SocketAddress(std::string ip, int port);
SocketAddress(std::string ip);
std::string ip;
int port;
std::string asString();
bool hasPort();
};

class HttpRequest{
    public:
    HttpRequest(){}
    HttpRequest(std::string method,std::string path){
        setMethod(method);
        setPath(path);
    }
    HttpRequest(std::string method,std::string path, std::string* body){
        setMethod(method);
        setPath(path);
        std::ostream& buff = setBody();
        buff << *body;
        buff.flush();
    }

    virtual std::istream& getBody();
    virtual std::ostream& setBody();

    virtual std::string getMethod();
    virtual void setMethod(std::string method);

    virtual std::string getPath();
    virtual void setPath(std::string path);

    virtual std::string getHeader(std::string key);
    virtual dict* getAllHeaders();
    virtual void setHeader(std::string key, std::string value);

    virtual bool canUpgradeToWs();
    virtual WebSocket* upgrade();
};

class HttpResponse{
public:
    HttpResponse(){}
    HttpResponse(int code, std::string statusText){
        setStatus(code, statusText);
    }
    HttpResponse(int code, std::string statusText, std::string* body){
        setStatus(code, statusText);
        std::ostream& buff = setBody();
        buff << *body;
        buff.flush();
    }

    virtual std::istream& getBody();
    virtual std::ostream& setBody();

    virtual int getStatus();
    virtual std::string getStatusText();
    virtual void setStatus(int code, std::string text);

    virtual std::string getHeader(std::string key);
    virtual dict* getAllHeaders();
    virtual void setHeader(std::string key, std::string value);
};

class TcpRequest{
    
};

class ServerSocket{
    public:
        ServerSocket(){

        }
        virtual bool start();
        virtual bool stop();
};

class WebSocket{
    public:
        WebSocket(){}
        virtual int receive(void *buffer, int length);
        virtual void send(void *buffer, int length);
};

class TcpConnectionHandeler{

};

class HttpReqHandeler{
public:
    HttpReqHandeler();
    virtual void handle(HttpRequest* req, HttpResponse* res);
};

class HttpReqHandlerFactory{
    public:
    virtual HttpReqHandeler* create();
};

class TcpConnHandlerFactory{
    public:
    virtual TcpConnectionHandeler* create();
};

class HttpServer: public ServerSocket{
    
};

class UdpSocket{
    
};

class TcpServer: public ServerSocket{
    public:
     TcpServer(SocketAddress addr, TcpConnectionHandeler *connHandeler);
};

class TcpClient{
    public:
     TcpClient(SocketAddress addr, TcpConnectionHandeler *connHandeler);
};

class NetworkStack{
    public:
    virtual TcpServer* CreateTcpServer();
    virtual TcpClient* CreateTcpClient();
    virtual HttpServer* CreateHttpServer();
    virtual UdpSocket* CreateUdpSocket();
};

}

#endif