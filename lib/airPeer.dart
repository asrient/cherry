//import 'package:multicast_dns/multicast_dns.dart';
import 'dart:io';
import 'package:dns/dns.dart';
import 'dart:async';
//import 'package:device_info_plus/device_info_plus.dart';
import 'package:eventify/eventify.dart';
import 'package:raw/raw.dart';
import 'dart:typed_data';
//import 'package:buffer/buffer.dart';

///////////////////////////////////////
BigInt byte8max = BigInt.parse("18446744073709551615");
int intMax = 9223372036854775807;
//////////////////////////////////////

class AirId {
  static isEqual(id1, id2) {
    return id1.airId == id2.airId;
  }

  var airId;
  AirId({airId, String? uid, String? host, String? sessionId}) {
    if (airId is AirId) {
      this.airId = airId.str;
    } else if (airId is String && airId.split(':').length > 1) {
      this.airId = airId;
    } else if (host != null && uid != null) {
      if (sessionId != null) {
        this.airId = '$uid:$host:$sessionId';
      } else {
        this.airId = '$uid:$host';
      }
    }
  }
  parse() {
    var ids = this.airId.split(':');
    return {"uid": ids[0], "host": ids[1], "sessionId": ids[2]};
  }

  String get str {
    return this.airId;
  }

  String get host {
    return this.airId.split(':')[1];
  }

  set host(String str) {
    this.airId = '${this.airId.split(':')[0]}:$str:${this.airId.split(':')[1]}';
  }

  String get uid {
    return this.airId.split(':')[0];
  }

  set uid(String str) {
    this.airId = '$str:${this.airId.split(':')[0]}:${this.airId.split(':')[1]}';
  }

  String? get sessionId {
    var arr = this.airId.split(':');
    if (arr.length == 3) {
      return arr[2];
    }
    return null;
  }

  set sessionId(String? str) {
    if (str != null)
      this.airId =
          '${this.airId.split(':')[0]}:${this.airId.split(':')[1]}:$str';
    else
      this.airId = '${this.airId.split(':')[0]}:${this.airId.split(':')[1]}';
  }

  bool get isLocal {
    if (this.sessionId != null) {
      return this.sessionId!.split('#').length == 2;
    }
    return false;
  }

  String? get ipAddr {
    if (this.isLocal && this.sessionId != null) {
      return this.sessionId!.split('#')[0];
    }
    return null;
  }

  get port {
    if (this.isLocal && this.sessionId != null) {
      return this.sessionId!.split('#')[1];
    }
    return null;
  }
}

parseAirId(String airId) {
  var ids = airId.split(':');
  return {"uid": ids[0], "host": ids[1], "sessionId": ids[2]};
}

const c = {
  "FRAME_SIZE": 64535, //65535
  "VERSION": '1.1'
};

Future getIpAddrs() async {
  //TODO: Fix for android, use wifi package
  var obj = {};
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type.name == 'IPv4' &&
          addr.address != '127.0.0.1' &&
          !addr.isLoopback) {
        obj[interface.name] = addr.address;
      }
    }
  }
  return obj;
}

getIpAddr() async {
  //This will return the most probable IP address of WiFi
  var ips = await getIpAddrs();
  if (ips.containsKey('Wi-Fi')) return ips['Wi-Fi'];
  if (ips.containsKey('en0')) return ips['en0'];
  return ips.toList()[0].value;
}

getDeviceName() {
  //DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //print(deviceInfo);
  var envVars = Platform.environment;
  //print(envVars);
  if (envVars.containsKey('COMPUTERNAME')) return envVars['COMPUTERNAME'];
  return "Cherry device";
}

////////////////////////////////////////////
class DnsData {
  String ipAddr;
  int port;
  DnsPacket packet;
  DnsData(this.ipAddr, this.port, this.packet);
  void prnt() {
    Function typ = DnsResourceRecord.stringFromType;
    print("\n-----DNS Id:${packet.id}-----");
    print("From: $ipAddr:$port");
    if (packet.isResponse) {
      print("Type: Response");
    } else {
      print("Type: Query");
    }
    print("\n");
    for (DnsQuestion q in packet.questions) {
      print("Question: ${q.name}");
    }
    print("\n");
    for (DnsResourceRecord a in packet.answers) {
      print("Answer: ${a.name}");
      print("Type ${typ(a.type)}");
      print(String.fromCharCodes(a.data));
    }
    print("\n");
    for (DnsResourceRecord a in packet.authorities) {
      print("authorities: ${a.name}");
      print("Type ${typ(a.type)}");
      print(String.fromCharCodes(a.data));
    }
    print("\n");
    for (DnsResourceRecord a in packet.additionalRecords) {
      print("additional: ${a.name}");
      print("Type ${typ(a.type)}");
      print(String.fromCharCodes(a.data));
    }
    print("---------------------------");
  }
}

class Bonjour extends EventEmitter {
  static const port = 5353;
  RawDatagramSocket? socket;
  _receivedDatagram(Datagram d) {
    //String message = new String.fromCharCodes(d.data).trim(); //
    //print('Datagram from ${d.address.address}:${d.port}: $message'); //
    var packet = DnsPacket();
    packet.decodeSelf(RawReader.withBytes(d.data));
    var dnsData = DnsData(d.address.address, d.port, packet);
    if (packet.answers.isNotEmpty) {
      packet.isResponse = true;
      this.emit("response", null, dnsData);
    } else {
      this.emit("query", null, dnsData);
    }
  }

  Bonjour() {
    RawDatagramSocket.bind(InternetAddress("224.0.0.251"), Bonjour.port)
        .then((RawDatagramSocket socket) {
      socket.multicastLoopback = true;
      socket.joinMulticast(InternetAddress("224.0.0.251"));
      //print('Datagram socket ready to receive'); //
      //print('${socket.address.address}:${socket.port}'); //
      this.socket = socket;
      this.emit("connected", '${socket.address.address}:${socket.port}');
      socket.listen((RawSocketEvent e) {
        while (true) {
          final datagram = socket.receive();
          if (datagram == null) {
            break;
          }
          this._receivedDatagram(datagram);
        }
      });
    });
  }
  send(DnsPacket packet) {
    socket?.send(packet.toImmutableBytes(), InternetAddress("224.0.0.251"),
        Bonjour.port);
  }

  query(DnsPacket packet, Function cb) {
    if (!packet.isResponse) {
      cb(null);
    } else {
      send(packet);
    }
  }
}

/////////////////////////////////////////

class Frame {
  static parseChunk(ByteData blob) {
    if (blob.lengthInBytes >= 11) {
      //Now we are sure all the headers are there
      final int firstByte = blob.getUint8(0);
      final bool isFinalFrame = firstByte as bool;
      final key = ByteData.sublistView(blob, 1, 9);
      final size = blob.getInt16(9);
      if (blob.lengthInBytes >= size + 11) {
        //To make sure full payload exists
        final buff = ByteData.sublistView(blob, 11, 11 + size);
        ByteData? remaining;
        if (blob.lengthInBytes > size + 11) {
          remaining = ByteData.sublistView(blob, 11 + size);
        }
        return {
          "chunk": {
            "data": buff,
            "key": key,
            "size": size,
            "fin": isFinalFrame
          },
          "remaining": remaining
        };
      } else
        return {"chunk": null, "remaining": blob};
    } else
      return {"chunk": null, "remaining": blob};
  }

  static parse(ByteData buffer) {
    ByteData? remaining = buffer;
    var chunks = [];
    var done = false;
    while (remaining != null && !done) {
      var res = Frame.parseChunk(remaining);
      if (res.chunk != null) {
        chunks.add(res.chunk);
      } else {
        done = true;
      }
      remaining = res.remaining;
    }
    return {"chunks": chunks, "roaming": remaining};
  }

  static build(bool fin, ByteData key, ByteData data) {
    var firstByte = ByteData(1);
    firstByte.setUint8(0, 1);
    if (!fin) {
      firstByte.setUint8(0, 0);
    }
    if (key.lengthInBytes != 8) {
      print("Key not 8 bytes ${key.lengthInBytes}");
    }
    var size = ByteData(2);
    size.setInt16(0, data.lengthInBytes);
    var header = firstByte.buffer.asUint8List() +
        key.buffer.asUint8List() +
        size.buffer.asUint8List();
    var lst = data.buffer.asUint8List();
    lst.insertAll(0, header);
    ByteData buff = lst.buffer.asByteData();
    if (buff.lengthInBytes > (c["FRAME_SIZE"] as int)) {
      print("Cannot build frame. Buffer size should be < 64KB, current size: " +
          (buff.lengthInBytes / 1024).toString() +
          " KB");
      return null;
    } else
      return buff;
  }
}

const seperator = "\r\n\r\n";
final sepLen = 4;

class Message {
  static const types = ['connect', 'connected', 'request', 'response'];
  final sep = "\r\n";
  var isEncoded = false;
  String version = "1.1";
  late String type;
  AirId? airId;
  int? port;
  String? name;
  String? icon;
  String? app;
  AirId? to;
  AirId? from;
  int? status;
  var body;

  Message(
      {required this.type,
      this.airId,
      this.port,
      this.name,
      this.icon,
      this.app,
      this.to,
      this.from,
      this.status,
      required this.body,
      this.version = "1.1"});

  static int? offsetIndex(ByteData buff) {
    bool found = false;
    var offset = 0;
    while (!found && offset + sepLen < buff.lengthInBytes) {
      found = ByteData.sublistView(buff, offset, offset + sepLen).toString() ==
          seperator;
      if (!found) {
        offset++;
      }
    }
    if (found)
      return offset;
    else
      return null;
  }

  static Message? tryDecode(ByteData buff) {
    var offset = offsetIndex(buff);
    if (offset != null) {
      return Message.fromBuffer(buff, offset);
    } else
      return null;
  }

  Message.fromBuffer(ByteData buff, int? offset) {
    //use inside try catch
    Map<String, String?> tmp = {"uid": null, "host": null, "sessionid": null};
    if (offset == null) offset = offsetIndex(buff)!;
    body = ByteData.sublistView(buff, offset + sepLen);
    var head = ByteData.sublistView(buff, 0, offset).toString();
    var opts = head.split("\r\n");
    opts.asMap().forEach((ind, opt) {
      if (ind == 0) {
        String _type = opt.split(' ')[0];
        if (opt.split(' ').length > 1) {
          var protocol = opt.split(' ')[1];
          if (protocol == 'AIR/' + version) {
            _type = _type.toLowerCase();
            if (types.contains(type)) {
              type = type;
            }
          }
        }
      } else if (opt.split('=').length == 2) {
        var key = opt.split('=')[0];
        var val = opt.split('=')[1];
        key = key.toLowerCase();
        key = key.trim();
        val = val.trim();
        if (key.isNotEmpty && val.isNotEmpty) {
          if (key == 'uid' && type == 'connect') {
            tmp[key] = val;
          }
          if (key == 'host' && type == 'connect') {
            tmp[key] = val;
          }
          if (key == 'sessionid' && type == 'connect') {
            tmp[key] = val;
          }
          if (key == 'port' && type == 'connect') {
            port = val as int;
          }
          if (key == 'app' && type == 'connect') {
            app = val;
          }
          if (key == 'name' && type == 'connect') {
            name = val;
          }
          if (key == 'airid' && type == 'connected') {
            airId = new AirId(airId: val);
          }
          if (type == 'request' || type == 'response') {
            if (key == 'to') {
              to = new AirId(airId: val);
            }
            if (key == 'from') {
              from = new AirId(airId: val);
            }
            if (type == 'response' && key == 'status') {
              status = val as int;
            }
          }
        }
      } else {
        print("DEBUG: corrupt header field " + opt);
      }
    });
    if (airId == null && tmp["uid"] != null && tmp["host"] != null) {
      airId = AirId(
          uid: tmp["uid"], host: tmp["host"], sessionId: tmp["sessionid"]);
    }
  }

  ByteData toBuffer() {
    //encode
    if (isEncoded) {
      print("WARNING: message already encoded once");
      return body;
    }
    var msg = "";
    msg += type + " AIR/" + version + sep;
    if (type == 'connect' && airId != null) {
      msg += "uid=" + airId!.uid + sep;
    }
    if (type == 'connect' && airId != null) {
      msg += "host=" + airId!.host + sep;
    }
    if (type == 'connect' && airId?.sessionId != null) {
      msg += "sessionid=" + airId!.sessionId! + sep;
    }
    if (type == 'connect' && port != null) {
      msg += "port=" + port!.toString() + sep;
    }
    if (type == 'connect' && name != null) {
      msg += "name=" + name! + sep;
    }
    if (type == 'connect' && icon != null) {
      msg += "icon=" + icon! + sep;
    }
    if (type == 'connect' && app != null) {
      msg += "app=" + app! + sep;
    }
    if (type == 'connected' && airId != null) {
      msg += "airid=" + airId!.str + sep;
    }
    if (type == 'request' || type == 'response') {
      if (to != null) {
        msg += "to=" + to!.str + sep;
      }
      if (from != null) {
        msg += "from=" + from!.str + sep;
      }
      if (type == 'response' && status != null) {
        msg += "status=" + status!.toString() + sep;
      }
    }

    msg += sep;
    if (body is String || body == null) {
      msg += body;
      return Uint8List.fromList(msg.codeUnits).buffer.asByteData();
    }
    var headerList = msg.codeUnits;
    var bodyList = body.buffer.asUint8List();
    bodyList.insertAll(0, headerList);
    ByteData buff = bodyList.buffer.asByteData();
    return buff;
  }

  ByteData bodyAsBuffer() {
    if (body is String) {
      return Uint8List.fromList(body.codeUnits).buffer.asByteData();
    }
    return body as ByteData;
  }
}

class MessageStream {
  Message? m;
  late StreamController<ByteData> _s;
  Function onReady;

  add(ByteData buff) {
    if (m == null) {
      m = Message.tryDecode(buff);
      if (m != null) {
        onReady(this);
        _s.add(m!.bodyAsBuffer());
      }
    } else
      _s.add(buff);
  }

  done() {
    _s.close();
  }

  Stream<ByteData> get stream {
    return _s.stream;
  }

  MessageStream(this.onReady) {
    _s = StreamController<ByteData>();
  }
}

/////////////////////////////////////////

class LocalSocket {
  bool isConnected = false;
  String ip;
  int port;
  Socket? socket;
  LocalSocket(this.ip, this.port) {
    this.isConnected = false;
    Socket.connect(ip, port).then((soc) {
      this.socket = soc;
      this.isConnected = true;
    });
    //this.socket.setNoDelay(true);
    socket?.listen(
      // handle data from the server
      (Uint8List data) {
        final serverResponse = String.fromCharCodes(data); //
        print('Server: $serverResponse'); //
      },

      // handle errors
      onError: (error) {
        print(error);
        this.end();
      },
      // handle server ending connection
      onDone: () {
        this.end();
      },
    );
  }
  send(List<int> msg) {
    this.socket?.add(msg);
    //maybe flush afterwards
  }

  end() {
    this.isConnected = false;
    this.socket?.destroy();
  }
}

class Local {
  bool isInit = false;
  ServerSocket? _server;
  AirId? airId;
  start(String ipAddr) {
    ServerSocket.bind(InternetAddress.anyIPv4, 0).then((srv) {
      _server = srv;
      isInit = true;
      airId?.sessionId = ipAddr + '#' + _server!.port.toString();
      _server!.listen((client) {
        _handleConnection(client);
      });
      // TODO: 1) add events listners for bonjour here
      // 2)Do a bonjour query
    });
  }

  stop() {
    if (_server != null) {
      _server?.close();
      airId?.sessionId = null;
    }
  }

  set ipAddr(ip) {
    if (this._server != null) this.stop();
    this.start(ip);
  }

  get ipAddr {
    return this.airId?.ipAddr;
  }

  void _handleConnection(Socket client) {
    String cAddr = client.remoteAddress.address;
    int cPort = client.remotePort;
    if (client.remoteAddress.type == InternetAddressType.IPv6) {
      cAddr = cAddr.split('::ffff:')[1];
    }
    print('Connection from $cAddr:$cPort'); //
    ByteData? roaming;
    bool isDone = false;
    late ByteData key;
    final msg = MessageStream((msg) {
      //on ready, headers decoded
      Message m = msg.m;
      if (m.airId!.isLocal) {
        if (m.type == 'request') {
          //console.log('req from local client', m);
          //this.emit('request', {key, message: m});
        } else if (m.type == 'response') {
          //console.log('res from local client', m);
          //this.emit('response', {key, message: m});
        }
      } else {
        print(
            "got a msg from global address in local server $cAddr:${cPort.toString()} ${m.type} ${m.from?.str}");
      }
    });
    done() {
      // All data received
      if (!isDone) {
        msg.done();
        isDone = true;
        client.close();
      }
    }

    // listen for events from the client
    client.listen(
      // handle data from the client
      (Uint8List data) async {
        if (roaming != null) {
          roaming?.buffer.asUint8List().addAll(data);
        } else
          roaming = data.buffer.asByteData();
        final parsedFrame = Frame.parse(roaming!);
        roaming = parsedFrame.roaming;
        List chunks = parsedFrame.chunks;
        chunks.forEach((chunk) {
          key = chunk.key;
          bool fin = chunk.fin;
          ByteData data = chunk.data;
          msg.add(data);
          if (fin) done();
        });
      },
      // handle errors
      onError: (error) {
        print(error);
        done();
      },
      // handle the client closing the connection
      onDone: () {
        print('Client left');
        done();
      },
    );
  }
}

main() {
  var x = AirId(airId: "gfh");
  getIpAddr().then((ip) {
    print(ip);
  });
  print(getDeviceName());
  Bonjour b = Bonjour();
  b.on("query", null, (env, _) {
    DnsData d = env.eventData as DnsData;
    d.prnt();
  });
  b.on("response", null, (env, _) {
    DnsData d = env.eventData as DnsData;
    d.prnt();
  });
}
