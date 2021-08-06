#include <iostream>
#include <sstream>
#include <cstring>
#include <iomanip>
#include <string>

#include "../include/net.h"

using namespace net;

////////// SocketAddress ////////////

SocketAddress::SocketAddress(std::string ip, int port)
{
    this->ip = ip;
    this->port = port;
}

SocketAddress::SocketAddress(std::string address)
{
    std::string ip = address.substr(0, address.find(":"));
    std::string port = address.substr(address.find(":") + 1);
    if (port == ip)
    {
        this->port = NULL;
    }
    else
    {
        this->port = std::stoi(port);
    }
    this->ip = ip;
}

std::string SocketAddress::asString()
{
    std::string st = ip;
    if (port != NULL)
    {
        st += ":" + std::to_string(port);
    }
    return st;
}

bool SocketAddress::hasPort()
{
    return port != NULL;
}

////////// SocketAddress ////////////
