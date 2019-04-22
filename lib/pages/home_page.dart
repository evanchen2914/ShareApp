import 'dart:async';
import 'package:shareapp/main.dart';
import 'package:flutter/material.dart';
import 'package:shareapp/rentals/chat.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/services/auth.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/models/user_edit.dart';
import 'package:shareapp/pages/item_detail.dart';
import 'package:shareapp/pages/profile_edit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shareapp/rentals/rental_detail.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomePage extends StatefulWidget {
  static const routeName = '/homePage';

  BaseAuth auth;
  FirebaseUser firebaseUser;
  VoidCallback onSignOut;

  HomePage({this.auth, this.firebaseUser, this.onSignOut});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  SharedPreferences prefs;
  List<Item> itemList;

  String userID;
  int currentTabIndex;

  EdgeInsets edgeInset;
  double padding;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    currentTabIndex = 0;

    padding = 12;
    edgeInset = EdgeInsets.all(padding);

    userID = widget.firebaseUser.uid;

    setPrefs();

    handleInitUser();
  }

  void setPrefs() async {
    prefs = await SharedPreferences.getInstance();
    await prefs.setString('userID', userID);
  }

  void handleInitUser() async {
    // get user object from firestore
    Firestore.instance
        .collection('users')
        .document(userID)
        .get()
        .then((DocumentSnapshot ds) {
      // if user is not in database, create user
      if (!ds.exists) {
        Firestore.instance.collection('users').document(userID).setData({
          'displayName': widget.firebaseUser.displayName,
          'photoURL': widget.firebaseUser.photoUrl,
          'email': widget.firebaseUser.email,
          'lastActiveTimestamp': DateTime.now().millisecondsSinceEpoch,
          'accountCreationTimestamp':
              widget.firebaseUser.metadata.creationTimestamp,
        });
      }

      // if user is already in db
      else {
        //Firestore.instance.collection('users').document(userID).updateData({});
      }
    });

    //sleep(const Duration(seconds:1));
  }

  @override
  Widget build(BuildContext context) {
    Firestore.instance
        .collection('users')
        .document(userID)
        .get()
        .then((DocumentSnapshot ds) {
      Firestore.instance.collection('users').document(userID).updateData({
        'lastActiveTimestamp': DateTime.now().millisecondsSinceEpoch,

        /// TAKE BELOW TWO LINES OUT SOON
        'email': widget.firebaseUser.email,

        'accountCreationTimestamp':
            widget.firebaseUser.metadata.creationTimestamp,
      });
    });

    final bottomTabPages = <Widget>[
      homeTabPage(),
      rentalsTabPage(),
      myListingsTabPage(),
      messagesTabPage(),
      profileTabPage(),
    ];

    final bottomNavBarTiles = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.search), title: Text('Search')),
      BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart), title: Text('Rentals')),
      BottomNavigationBarItem(
          icon: Icon(Icons.style), title: Text('My Listings')),
      BottomNavigationBarItem(icon: Icon(Icons.forum), title: Text('Messages')),
      BottomNavigationBarItem(
          icon: Icon(Icons.account_circle), title: Text('Profile')),
      //more_horiz
      //view_headline
    ];
    assert(bottomTabPages.length == bottomNavBarTiles.length);
    final bottomNavBar = BottomNavigationBar(
      items: bottomNavBarTiles,
      currentIndex: currentTabIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (int index) {
        setState(() {
          currentTabIndex = index;
        });
      },
    );

    return Scaffold(
      /*appBar: AppBar(title: Text('ShareApp'), actions: <Widget>[
        IconButton(
          icon: Icon(Icons.exit_to_app),
          tooltip: 'Sign out',
          onPressed: () {
            logout();
          },
        ),
      ]),*/
      body: bottomTabPages[currentTabIndex],
      floatingActionButton: showFAB(),
      bottomNavigationBar: bottomNavBar,
    );
  }

  FloatingActionButton showFAB() {
    if (currentTabIndex == 2) {
      return FloatingActionButton(
        onPressed: () {
          navigateToEdit(
            Item(
              id: null,
              status: true,
              creator: Firestore.instance.collection('users').document(userID),
              name: '',
              description: '',
              type: null,
              condition: null,
              price: 0,
              numImages: 0,
              images: new List(),
              location: null,
              rental: null,
            ),
          );
        },
        tooltip: 'Add new item',
        child: Icon(Icons.add),
      );
    }

    return null;
  }

  Widget homeTabPage() {
    return Padding(
      padding: edgeInset,
      child: Column(
        children: <Widget>[
          Container(
            child: showSignedInAs(),
          ),
          Container(
            height: 10,
          ),
          reusableObjList('All items', buildItemList()),
        ],
      ),
    );
  }

  Widget rentalsTabPage() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: <Widget>[
          reusableObjList(
              'Items I\'m currently renting', buildRentalsListCurrent()),
          Container(
            height: padding,
          ),
          reusableObjList(
              'Items I have requested to rent', buildRentalsListRequested()),
        ],
      ),
    );
  }

  Widget reusableObjList(String heading, displayList) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              heading,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.grey[350],
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
          ),
          Container(
            height: 12,
          ),
          displayList,
        ],
      ),
    );
  }

  Widget myListingsTabPage() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: <Widget>[
          reusableObjList(
            'My items that are available to rent',
            buildMyListingsListAvailable(),
          ),
          Container(
            height: padding,
          ),
          reusableObjList(
            'My items that are currently being rented',
            buildMyListingsListRented(),
          ),
        ],
      ),
    );
  }

  Widget messagesTabPage() {
    return Padding(
      padding: edgeInset,
      child: Column(
        children: <Widget>[
          reusableObjList(
            'My messages',
            buildMessagesList(),
          ),
        ],
      ),
    );
  }

  Widget profileTabPage() {
    return Padding(
      padding: edgeInset,
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(10.0),
          ),
          profileIntro(),
          Divider(),
          profileTabAfterIntro(),
        ],
      ),
    );
  }

  Widget profileIntro() {
    return FutureBuilder(
      future: Firestore.instance.collection('users').document(userID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot ds = snapshot.data;
          return new Container(
            child: Column(
              children: <Widget>[
                // User Icon
                Container(
                  padding: EdgeInsets.only(left: 15.0),
                  alignment: Alignment.topLeft,
                  height: 60.0,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      key: new ValueKey<String>(
                          DateTime.now().millisecondsSinceEpoch.toString()),
                      imageUrl: ds['photoURL'],
                      placeholder: (context, url) => new Container(),
                    ),
                  ),
                ),
                // username
                Container(
                    padding: const EdgeInsets.only(top: 8.0, left: 15.0),
                    alignment: Alignment.centerLeft,
                    child: Text('${ds['displayName']}',
                        style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Quicksand'))),
                // email
                Container(
                    padding: const EdgeInsets.only(top: 4.0, left: 15.0),
                    alignment: Alignment.centerLeft,
                    child: Text('${ds['email']}',
                        style: TextStyle(
                            fontSize: 15.0, fontFamily: 'Quicksand'))),
                //
                Container(
                    alignment: Alignment.centerLeft,
                    child: FlatButton(
                      child: Text("Edit Profile",
                          style: TextStyle(
                              color: Color(0xff007f6e),
                              fontFamily: 'Quicksand')),
                      onPressed: () => navToProfileEdit(),
                    )),
              ],
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget profileTabAfterIntro() {
    // [TEMPORARY SOLUTION]
    double height = (MediaQuery.of(context).size.height) - 310;
    return Container(
      height: height,
      child: ListView(
        children: <Widget>[
          reusableCategory("ACCOUNT SETTINGS"),
          reusableFlatButton(
              "Personal information", Icons.person_outline, null),
          reusableFlatButton("Payments and payouts", Icons.payment, null),
          reusableFlatButton("Notifications", Icons.notifications, null),
          reusableCategory("SUPPORT"),
          reusableFlatButton("Get help", Icons.help_outline, null),
          reusableFlatButton("Give us feedback", Icons.feedback, null),
          reusableFlatButton("Log out", null, logout),
          getProfileDetails()
        ],
      ),
    );
  }

  Widget reusableCategory(text) {
    return Container(
        padding: EdgeInsets.only(left: 15.0, top: 10.0),
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w100)));
  }

  Widget reusableFlatButton(text, icon, action) {
    return Column(
      children: <Widget>[
        Container(
          child: FlatButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(text, style: TextStyle(fontFamily: 'Quicksand')),
                Icon(icon)
              ],
            ),
            onPressed: () => action(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 15.0,
            right: 15.0,
          ),
          child: Divider(),
        )
      ],
    );
  }

  Widget getProfileDetails() {
    return FutureBuilder(
      future: Firestore.instance.collection('users').document(userID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot ds = snapshot.data;
          List<String> details = new List();
          details.add(ds.documentID);
          details.add(ds['email']);
          var date1 = new DateTime.fromMillisecondsSinceEpoch(
              ds['accountCreationTimestamp']);
          details.add(date1.toString());

          var date2 = new DateTime.fromMillisecondsSinceEpoch(
              ds['lastActiveTimestamp']);
          details.add(date2.toString());
          return Column(
            children: <Widget>[
              Container(
                height: 15,
              ),
              Text('User ID: ${details[0]}',
                  style: TextStyle(
                      color: Colors.black54,
                      fontFamily: 'Quicksand',
                      fontSize: 13.0)),
              Container(
                height: 15,
              ),
              Text('Account creation: ${details[2]}',
                  style: TextStyle(
                      color: Colors.black54,
                      fontFamily: 'Quicksand',
                      fontSize: 13.0)),
              Container(
                height: 15,
              ),
              Text('Last active: ${details[3]}',
                  style: TextStyle(
                      color: Colors.black54,
                      fontFamily: 'Quicksand',
                      fontSize: 13.0)),
            ],
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget showSignedInAs() {
    return FutureBuilder(
      future: Firestore.instance.collection('users').document(userID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot ds = snapshot.data;

          return new Text(
            'Signed in as: ${ds['displayName']}',
            style: TextStyle(fontStyle: FontStyle.italic),
          );
        } else {
          return new Text('');
        }
      },
    );
  }

  Widget buildItemList() {
    CollectionReference collectionReference =
        Firestore.instance.collection('items');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference.snapshots(),
        // to show all items created by you
        //where('creator', isEqualTo: Firestore.instance.collection('users').document(userID)),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];

                  Icon tileIcon;
                  String itemType = ds['type'];

                  switch (itemType) {
                    case 'tool':
                      tileIcon = Icon(Icons.build);
                      break;
                    case 'leisure':
                      tileIcon = Icon(Icons.golf_course);
                      break;
                    case 'home':
                      tileIcon = Icon(Icons.home);
                      break;
                    case 'other':
                      tileIcon = Icon(Icons.device_unknown);
                      break;
                  }

                  return ListTile(
                    leading: tileIcon,
                    //leading: Icon(Icons.build),
                    title: Text(
                      ds['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(ds['description']),
                    onTap: () {
                      DocumentReference dr = ds['creator'];
                      navigateToDetail(ds.documentID);
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteItemDialog(ds);
                      },
                    ),
                  );
                },
              );
          }
        },
      ),
    );
  }

  Widget buildRentalsList() {
    CollectionReference collectionReference =
        Firestore.instance.collection('rentals');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference.snapshots(),
        // to show all items created by you
        //where('creator', isEqualTo: Firestore.instance.collection('users').document(userID)),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];
                  bool showChat = false;

                  DocumentReference renterDR = ds['renter'];
                  DocumentReference ownerDR = ds['owner'];

                  if (userID == renterDR.documentID ||
                      userID == ownerDR.documentID) {
                    showChat = true;
                  }

                  return ListTile(
                    leading: Icon(Icons.shopping_cart),
                    //leading: Icon(Icons.build),
                    title: Text(
                      ds.documentID,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${ds['start'].toString()}'),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RentalDetail.routeName,
                        arguments: ItemRentalArgs(
                          ds.documentID,
                        ),
                      );
                    },
                    trailing: showChat
                        ? IconButton(
                            icon: Icon(Icons.message),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                Chat.routeName,
                                arguments: ChatArgs(
                                  ds.documentID,
                                ),
                              );
                            },
                          )
                        : null,
                  );
                },
              );
          }
        },
      ),
    );
  }

  Widget buildRentalsListCurrent() {
    CollectionReference collectionReference =
        Firestore.instance.collection('rentals');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference.snapshots(),
        // to show all items created by you
        //where('creator', isEqualTo: Firestore.instance.collection('users').document(userID)),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];
                  DocumentReference itemDR = ds['item'];

                  return FutureBuilder(
                    future: itemDR.get(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        DocumentSnapshot itemDS = snapshot.data;

                        if (ds['status'] != 1) {
                          bool showChat = false;

                          DocumentReference renterDR = ds['renter'];
                          DocumentReference ownerDR = ds['owner'];

                          if (userID == renterDR.documentID ||
                              userID == ownerDR.documentID) {
                            showChat = true;
                          }

                          String created = 'Created: ' +
                              timeago.format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      ds['created']));

                          return ListTile(
                            leading: Icon(Icons.shopping_cart),
                            //leading: Icon(Icons.build),
                            title: Text(
                              itemDS['name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(created),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RentalDetail.routeName,
                                arguments: ItemRentalArgs(
                                  ds.documentID,
                                ),
                              );
                            },
                            trailing: showChat
                                ? IconButton(
                                    icon: Icon(Icons.message),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        Chat.routeName,
                                        arguments: ChatArgs(
                                          ds.documentID,
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          );
                        } else {
                          return Container();
                        }
                      } else {
                        return Container();
                      }
                    },
                  );
                },
              );
          }
        },
      ),
    );
  }

  Widget buildRentalsListRequested() {
    CollectionReference collectionReference =
        Firestore.instance.collection('rentals');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference.snapshots(),
        // to show all items created by you
        //where('creator', isEqualTo: Firestore.instance.collection('users').document(userID)),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];
                  DocumentReference itemDR = ds['item'];

                  return FutureBuilder(
                    future: itemDR.get(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        DocumentSnapshot itemDS = snapshot.data;

                        if (ds['status'] == 1) {
                          bool showChat = false;

                          DocumentReference renterDR = ds['renter'];
                          DocumentReference ownerDR = ds['owner'];

                          if (userID == renterDR.documentID ||
                              userID == ownerDR.documentID) {
                            showChat = true;
                          }

                          String created = 'Created: ' +
                              timeago.format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      ds['created']));

                          return ListTile(
                            leading: Icon(Icons.shopping_cart),
                            //leading: Icon(Icons.build),
                            title: Text(
                              itemDS['name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(created),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RentalDetail.routeName,
                                arguments: ItemRentalArgs(
                                  ds.documentID,
                                ),
                              );
                            },
                            trailing: showChat
                                ? IconButton(
                                    icon: Icon(Icons.message),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        Chat.routeName,
                                        arguments: ChatArgs(
                                          ds.documentID,
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          );
                        } else {
                          return Container();
                        }
                      } else {
                        return Container();
                      }
                    },
                  );
                },
              );
          }
        },
      ),
    );
  }

  Widget buildMyListingsList() {
    CollectionReference collectionReference =
        Firestore.instance.collection('items');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference
            .where('creator',
                isEqualTo:
                    Firestore.instance.collection('users').document(userID))
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];

                  Icon tileIcon;
                  String itemType = ds['type'];

                  switch (itemType) {
                    case 'tool':
                      tileIcon = Icon(Icons.build);
                      break;
                    case 'leisure':
                      tileIcon = Icon(Icons.golf_course);
                      break;
                    case 'home':
                      tileIcon = Icon(Icons.home);
                      break;
                    case 'other':
                      tileIcon = Icon(Icons.device_unknown);
                      break;
                  }

                  return ListTile(
                    leading: tileIcon,
                    //leading: Icon(Icons.build),
                    title: Text(
                      ds['name'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(ds['description']),
                    onTap: () {
                      DocumentReference dr = ds['creator'];
                      navigateToDetail(ds.documentID);
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        deleteItemDialog(ds);

                        /// ====================== ADD DELETE CONFIRMATION !!!
                      },
                    ),
                  );
                },
              );
          }
        },
      ),
    );
  }

  Widget buildMyListingsListAvailable() {
    CollectionReference collectionReference =
        Firestore.instance.collection('items');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference
            .where('creator',
                isEqualTo:
                    Firestore.instance.collection('users').document(userID))
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];

                  if (ds['rental'] == null) {
                    Icon tileIcon;
                    String itemType = ds['type'];

                    switch (itemType) {
                      case 'tool':
                        tileIcon = Icon(Icons.build);
                        break;
                      case 'leisure':
                        tileIcon = Icon(Icons.golf_course);
                        break;
                      case 'home':
                        tileIcon = Icon(Icons.home);
                        break;
                      case 'other':
                        tileIcon = Icon(Icons.device_unknown);
                        break;
                    }

                    return ListTile(
                      leading: tileIcon,
                      //leading: Icon(Icons.build),
                      title: Text(
                        ds['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(ds['description']),
                      onTap: () {
                        DocumentReference dr = ds['creator'];
                        navigateToDetail(ds.documentID);
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteItemDialog(ds);

                          /// ====================== ADD DELETE CONFIRMATION !!!
                        },
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              );
          }
        },
      ),
    );
  }

  Widget buildMyListingsListRented() {
    CollectionReference collectionReference =
        Firestore.instance.collection('items');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference
            .where('creator',
                isEqualTo:
                    Firestore.instance.collection('users').document(userID))
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.documents[index];

                  if (ds['rental'] != null) {
                    Icon tileIcon;
                    String itemType = ds['type'];

                    switch (itemType) {
                      case 'tool':
                        tileIcon = Icon(Icons.build);
                        break;
                      case 'leisure':
                        tileIcon = Icon(Icons.golf_course);
                        break;
                      case 'home':
                        tileIcon = Icon(Icons.home);
                        break;
                      case 'other':
                        tileIcon = Icon(Icons.device_unknown);
                        break;
                    }

                    return ListTile(
                      leading: tileIcon,
                      //leading: Icon(Icons.build),
                      title: Text(
                        ds['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(ds['description']),
                      onTap: () {
                        DocumentReference dr = ds['creator'];
                        navigateToDetail(ds.documentID);
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deleteItemDialog(ds);

                          /// ====================== ADD DELETE CONFIRMATION !!!
                        },
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              );
          }
        },
      ),
    );
  }

  Widget buildMessagesList() {
    CollectionReference collectionReference =
        Firestore.instance.collection('users');
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: collectionReference
            .document(userID)
            .collection('rentals')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return new Text('${snapshot.error}');
          }
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(
                child: new Container(),
              );
            default:
              return new ListView.builder(
                shrinkWrap: true,
                //padding: EdgeInsets.all(2.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot userRentalDS =
                      snapshot.data.documents[index];
                  DocumentReference rentalDR = userRentalDS['rental'];

                  return FutureBuilder(
                    future: rentalDR.get(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        DocumentSnapshot rentalDS = snapshot.data;
                        DocumentReference itemDR = rentalDS['item'];
                        DocumentReference ownerDR = rentalDS['owner'];
                        DocumentReference renterDR = rentalDS['renter'];

                        bool isRenter = userRentalDS['isRenter'];

                        Future<DocumentSnapshot> future =
                            isRenter ? ownerDR.get() : renterDR.get();

                        return FutureBuilder(
                          future: future,
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.hasData) {
                              DocumentSnapshot otherUserDS = snapshot.data;

                              String title = otherUserDS['displayName'];
                              String imageURL = otherUserDS['photoURL'];
                              String lastActive = 'Last seen: ' +
                                  timeago.format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          otherUserDS['lastActiveTimestamp']));

                              return ListTile(
                                leading: Container(
                                  height: 50,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      key: new ValueKey<String>(DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString()),
                                      imageUrl: imageURL,
                                      placeholder: (context, url) =>
                                          new Container(),
                                    ),
                                  ),
                                ),
                                //leading: Icon(Icons.build),
                                title: Text(
                                  title,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(lastActive),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    Chat.routeName,
                                    arguments: ChatArgs(
                                      rentalDS.documentID,
                                    ),
                                  );
                                },
                              );
                            } else {
                              return Container();
                            }
                          },
                        );
                      } else {
                        return Container();
                      }
                    },
                  );
                },
              );
          }
        },
      ),
    );

    /*
    return FutureBuilder(
      future: Firestore.instance.collection('users').document(userID).get(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          DocumentSnapshot userDS = snapshot.data;
          List<DocumentReference> rentals = List.from(userDS['rentals']);

          return new ListView.builder(
            shrinkWrap: true,
            //padding: EdgeInsets.all(2.0),
            itemCount: rentals.length,
            itemBuilder: (context, index) {
              debugPrint('*********${rentals[index].documentID}');
              rentals[index].get().then((DocumentSnapshot rentalDS) {

                return ListTile(
                  leading: Icon(Icons.chat_bubble),
                  //leading: Icon(Icons.build),
                  title: Text(
                    rentalDS.documentID,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(rentalDS['start'].toString()),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Chat.routeName,
                      arguments: ChatArgs(
                        rentalDS.documentID,
                      ),
                    );
                  },
                );
              });
            },
          );
        } else {
          return Container(
            child: Center(
              child: Text('error'),
            ),
          );
        }
      },
    );
    */
  }

  void navigateToEdit(Item newItem) async {
    Navigator.pushNamed(
      context,
      ItemEdit.routeName,
      arguments: ItemEditArgs(
        newItem,
      ),
    );
  }

  void navigateToDetail(String itemID) async {
    Navigator.pushNamed(
      context,
      ItemDetail.routeName,
      arguments: ItemDetailArgs(
        itemID,
      ),
    );
  }

  Future<UserEdit> getUserEdit() async {
    UserEdit out;
    DocumentSnapshot ds =
        await Firestore.instance.collection('users').document(userID).get();
    if (ds != null) {
      out = new UserEdit(
          id: userID, photoUrl: ds['photoURL'], displayName: ds['displayName']);
    }

    return out;
  }

  void navToProfileEdit() async {
    UserEdit userEdit = await getUserEdit();

    UserEdit result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ProfileEdit(
                userEdit: userEdit,
              ),
          fullscreenDialog: true,
        ));

    if (result != null) {
      Firestore.instance.collection('users').document(userID).updateData({
        'displayName': result.displayName,
        'photoURL': result.photoUrl,
      });
    }
  }

  Future<bool> deleteItemDialog(DocumentSnapshot ds) async {
    //if (widget.userEdit.displayName == userEditCopy.displayName) return true;

    final ThemeData theme = Theme.of(context);
    final TextStyle dialogTextStyle =
        theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete item?'),
              content: Text('${ds['name']}'),
              actions: <Widget>[
                FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(
                        false); // Pops the confirmation dialog but not the page.
                  },
                ),
                FlatButton(
                  child: const Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    deleteItem(ds);
                    // Pops the confirmation dialog but not the page.
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void deleteItem(DocumentSnapshot ds) {
    DocumentReference documentReference = ds.reference;
    Firestore.instance.collection('users').document(userID).updateData({
      'items': FieldValue.arrayRemove([documentReference])
    });

    deleteImages(ds.documentID, ds['numImages']);
    Firestore.instance.collection('items').document(ds.documentID).delete();
  }

  void deleteImages(String id, int numImages) async {
    for (int i = 0; i < numImages; i++) {
      FirebaseStorage.instance.ref().child('$id/$i').delete();
    }

    FirebaseStorage.instance.ref().child('$id').delete();
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }

  Future<DocumentSnapshot> getUserFromFirestore(String userID) async {
    DocumentSnapshot ds =
        await Firestore.instance.collection('users').document(userID).get();

    return ds;
  }

  void logout() async {
    try {
      await widget.auth.signOut();
      widget.onSignOut();
    } catch (e) {
      print(e);
    }
  }
}

void showSnackBar(BuildContext context, String item) {
  var message = SnackBar(
    content: Text("$item was pressed"),
    action: SnackBarAction(
        label: "Undo",
        onPressed: () {
          debugPrint('Performing dummy UNDO operation');
        }),
  );

  Scaffold.of(context).showSnackBar(message);
}