import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() => runApp(MyApp());

const apps = ["Photos", "Documents", "Messages"];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Cherry',
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: App(),
    );
  }
}

class App extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AppState();
}

class AppState extends State<App> {
  String currentTab = "Menu";
  Map<String, GlobalKey<NavigatorState>> navigatorKeys = {
    "Photos": GlobalKey<NavigatorState>(),
    "Documents": GlobalKey<NavigatorState>(),
    "Messages": GlobalKey<NavigatorState>(),
  };

  void _selectTab(String tabItem) {
    setState(() {
      currentTab = tabItem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          print("Back button pressed");
          return !await navigatorKeys[currentTab]!.currentState!.maybePop();
        },
        child: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: Stack(children: <Widget>[
                  _buildOffstageNavigator("Menu"),
                  _buildOffstageNavigator("Photos"),
                  _buildOffstageNavigator("Documents"),
                  _buildOffstageNavigator("Messages"),
                ]),
              ),
              Container(
                height: 30,
                color: Colors.cyanAccent,
                padding: EdgeInsets.all(2),
                child: Center(
                  child: Text("Status bar"),
                ),
              )
            ],
          ),
        ));
  }

  Widget _buildOffstageNavigator(String tabItem) {
    return Offstage(
      offstage: currentTab != tabItem,
      child: AppRouter(
          navKey: navigatorKeys[tabItem],
          appId: tabItem,
          changeApp: _selectTab),
    );
  }
}

class MenuPage extends StatelessWidget {
  MenuPage({
    Key? key,
    required this.changeApp,
  }) : super(key: key);
  final apps = ["Photos", "Documents", "Messages"];
  final Function changeApp;
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        backgroundColor: Colors.black12,
        child: Column(
          children: [
            Container(
              child: Center(
                child: Text("Menu"),
              ),
            ),
            Expanded(
              child: ListView(
                children: apps.map((item) {
                  return GestureDetector(
                    onTap: () {
                      changeApp(item);
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                      child: Text(item),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ));
  }
}

class AppRouter extends StatelessWidget {
  AppRouter({
    Key? key,
    required this.appId,
    this.navKey,
    this.changeApp,
  }) : super(key: key);
  final String appId;
  final GlobalKey<NavigatorState>? navKey;
  final Function? changeApp;
  @override
  Widget build(BuildContext context) {
    if (appId == "Menu") {
      return MenuPage(changeApp: changeApp!);
    }
    return Navigator(
        initialRoute: appId + '/demo',
        onGenerateRoute: (RouteSettings settings) {
          WidgetBuilder builder;
          var pth = settings.name?.split("/")[1];
          switch (pth) {
            case 'demo':
              // Assume CollectPersonalInfoPage collects personal info and then
              // navigates to 'signup/choose_credentials'.
              builder = (BuildContext context) =>
                  ListPage(appId: appId, closeApp: changeApp!);
              break;
            default:
              throw Exception('Invalid route: ${settings.name}');
          }
          return CupertinoPageRoute<void>(builder: builder, settings: settings);
        });
  }
}

class ListPage extends StatelessWidget {
  ListPage({Key? key, required this.appId, required this.closeApp})
      : super(key: key);
  final String appId;
  final Function closeApp;
  final items = ["Doggo", "Catto", "Bunny", "Froggo", "Floppa", "Birb"];
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: "Back",
        middle: Center(child: Text(appId)),
        trailing: GestureDetector(
            onTap: () {
              closeApp("Menu");
            },
            child: Icon(Icons.menu)),
      ),
      child: ListView(
        children: items.map((item) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => DetailsPage(
                    item: item,
                    closeApp: closeApp,
                  ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
              child: Text(item),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  DetailsPage({Key? key, required this.item, required this.closeApp})
      : super(key: key);
  final Function closeApp;
  final String item;
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        child: Column(
      children: [
        Container(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
            decoration: const BoxDecoration(
              color: Colors.white10,
              border: Border(
                bottom: BorderSide(width: 1.0, color: Colors.white10),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white10, shape: BoxShape.circle),
                    width: 20,
                    height: 20,
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(item,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white60,
                        )),
                  ),
                ),
                Container(
                  width: 30,
                  child: GestureDetector(
                      onTap: () {
                        closeApp("Menu");
                      },
                      child: Icon(Icons.menu)),
                )
              ],
            )),
        Center(
            child: CupertinoButton.filled(
          child: Icon(Icons.arrow_back_ios),
          onPressed: () {
            //Navigator.of(context).pop();
            DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
            print(deviceInfo);
          },
        )),
        OrientationBuilder(
          builder: (context, orientation) {
            return orientation == Orientation.portrait
                ? Text("Potrait")
                : Text("Landscape");
          },
        ),
      ],
    ));
  }
}
