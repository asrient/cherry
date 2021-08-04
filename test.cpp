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
#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#ifdef __APPLE__
#include <sys/types.h>
#endif
#include "include/dns/message.h"
#include "include/dns/exception.h"
#include "include/dns/rr.h"
#include <sstream>
#include <cstring>
#include <iomanip>
using namespace Poco::Net;
using namespace Poco::Util;
using namespace std;
using Poco::TaskManager;
using Poco::Task;


class TestTask : public Task {
public:

#define RX_BUFFER_SIZE 1024

TestTask() : Task("TestTask") {
}

void runTask() {

bool running = true;

Poco::Net::SocketAddress address("224.0.0.251", 5353);
/*
DatagramSocket dgs;

try {
  dgs.connect(sourceAddress);
}
catch (Poco::Net::NetException ne) {
  std::cout << ne.message() << std::endl;
}
catch (Poco::Exception e) {
  std::cout << e.what() << std::endl;
}
*/
 Poco::Net::MulticastSocket dsocket(
Poco::Net::SocketAddress(
 Poco::Net::IPAddress(), address.port()
 ), true
 );
 dsocket.setLoopback(true);
 // to receive any data you must join
 dsocket.joinGroup(address.host());
while (running) {

  sleep(10);
  cout << endl
             << "Listening for mdns" << endl;
  /*
  std::string msg = "Hello, world!";
dgs.sendBytes(msg.data(), msg.size());
  Poco::Net::SocketAddress sender;
  int n = dgs.receiveFrom(_rx_buffer, RX_BUFFER_SIZE, sender);
  _rx_buffer[n] = '\0';
  std::cout << sender.toString() << ": " << _rx_buffer << std::endl;

  //if (getchar() == 'Q') running = false;
  */

try {
    std::string msg = "Hello, world!";
//dsocket.sendTo(msg.data(), msg.size(),address); ///
}
catch (Poco::Net::NetException ne) {
  std::cout << ne.message() << std::endl;
}
catch (Poco::Exception e) {
  std::cout << e.what() << std::endl;
}
char buffer[512];
 Poco::Net::SocketAddress sender;
 int n = dsocket.receiveFrom(buffer, sizeof(buffer), sender);
 std::cout << sender.toString() << ": " << buffer << " len: " << n << std::endl;
 dns::Message m;
        try
        {
            m.decode(buffer, n);
        }
        catch (dns::Exception& e)
        {
            cout << "DNS exception occured when parsing incoming data: " << e.what() << endl;
            continue;
        }
            cout << "-------------------------------------------------------" << endl;
            cout << m.asString() << endl;
            
        // change type of message to response
        std::vector<dns::QuerySection*> queries = m.getQueries();
         std::cout << "queries{ ";

      for (int i=0; i<queries.size(); ++i)
      {
          std::cout << queries[i]->getName() << " ";
      }

      std::cout << "}" << std::endl;
      std::vector<dns::ResourceRecord*> ans = m.getAnswers();

      std::cout << "answers{ ";

      for (int i=0; i<ans.size(); ++i)
      {
          std::cout << ans[i]->getRData()->getType() << " " << ans[i]->getRData()->asString() << endl;
      }

      std::cout << "}" << std::endl;
      cout << "-------------------------------------------------------" << endl;
      if(m.getQr()==dns::Message::typeQuery){
 m.setQr(dns::Message::typeResponse&&ans.size()==0);
        // add NAPTR answer
        dns::ResourceRecord *rr = new dns::ResourceRecord();
        //rr->setName("test.air.local");
        rr->setType(dns::RDATA_TXT);
        rr->setClass(dns::CLASS_IN);
        dns::RDataTXT *rdata = new dns::RDataTXT();
        rdata->addTxt("test=data");
        rr->setRData(rdata);
        m.addAnswer(rr);
        char buffer2[512];
        uint mesgSize;
        m.encode(buffer2, 512, mesgSize);
        cout << "Sending -----------------------------------------------" << endl;
            cout << m.asString() << endl;
            cout << "-------------------------------------------------------" << endl;
      }
       
/*
  ofstream MyFile("out.txt", ios::out | ios::binary);
  // Write to the file
  MyFile.write((char *) &buffer, sizeof(buffer));
  // Close the file
  MyFile.close();
*/
}
}

private:
char _rx_buffer[RX_BUFFER_SIZE];

};



class MyRequestHandler : public HTTPRequestHandler
{
public:
    virtual void handleRequest(HTTPServerRequest &req, HTTPServerResponse &resp)
    {
        resp.setStatus(HTTPResponse::HTTP_OK);
        resp.setContentType("text/html");

        Poco::Net::NameValueCollection::ConstIterator i=req.begin();
        while(i!=req.end()){
          cout<<i->first<<": "<< i->second<<endl;
          i++;
        }
        ostream &out = resp.send();
        out << "<h1>Hello world!</h1>"
            << "<p>Count: " << ++count << "</p>"
            << "<p>Host: " << req.getHost() << "</p>"
            << "<p>Method: " << req.getMethod() << "</p>"
            << "<p>URI: " << req.getURI() << "</p>";
        out.flush();

        cout << endl
             << "Response sent for count=" << count
             << " and URI=" << req.getURI() << endl;
    }

private:
    static int count;
};

int MyRequestHandler::count = 0;

class MyRequestHandlerFactory : public HTTPRequestHandlerFactory
{
public:
    virtual HTTPRequestHandler *createRequestHandler(const HTTPServerRequest &)
    {
        return new MyRequestHandler;
    }
};



class MyServerApp : public ServerApplication
{
protected:
    int main(const vector<string> &)
    {
        HTTPServer s(new MyRequestHandlerFactory, ServerSocket(9090), new HTTPServerParams);
        HTTPServer s2(new MyRequestHandlerFactory, ServerSocket(2000), new HTTPServerParams);

        Poco::TaskManager tm;
        tm.start(new TestTask());

        s.start();
        s2.start();
        cout << endl
             << "Server started" << endl;
        
        waitForTerminationRequest(); // wait for CTRL-C or kill

        cout << endl
             << "Shutting down..." << endl;
        s.stop();
        s2.stop();
        tm.cancelAll();
        tm.joinAll();

        return Application::EXIT_OK;
    }
};

int main(int argc, char **argv)
{
    MyServerApp app;
    return app.run(argc, argv);
}

/*
Poco::Net::SocketAddress destAddress(destination_address, destination_port);
dgs.setBroadcast(true);
dgs.sendTo(data,dataLength, destAddress);
*/