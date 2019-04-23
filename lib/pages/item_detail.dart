import 'package:shareapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:shareapp/models/item.dart';
import 'package:shareapp/pages/item_edit.dart';
import 'package:shareapp/rentals/item_request.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ItemDetail extends StatefulWidget {
  static const routeName = '/itemDetail';
  final String itemID;

  //ItemDetail(this.itemID, this.isMyItem);
  ItemDetail({Key key, this.itemID}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ItemDetailState();
  }
}

class ItemDetailState extends State<ItemDetail> {
  String appBarTitle = "Item Details";
  GoogleMapController googleMapController;

  //List<String> imageURLs = List();
  String url;
  double padding = 5.0;

  //TextStyle textStyle;

  DocumentSnapshot itemDS;
  DocumentSnapshot creatorDS;
  SharedPreferences prefs;
  String myUserID;
  String itemCreator;

  bool isLoading;
  bool canRequest = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getMyUserID();
    //getItemCreatorID();

    getSnapshots();
  }

  void getMyUserID() async {
    prefs = await SharedPreferences.getInstance();
    myUserID = prefs.getString('userID') ?? '';
  }

  void getItemCreatorID() async {
    Firestore.instance
        .collection('items')
        .document(widget.itemID)
        .get()
        .then((DocumentSnapshot ds) {
      itemCreator = ds['creatorID'];
    });
  }

  void getSnapshots() async {
    isLoading = true;
    DocumentSnapshot ds = await Firestore.instance
        .collection('items')
        .document(widget.itemID)
        .get();

    if (ds != null) {
      itemDS = ds;

      DocumentReference dr = itemDS['creator'];
      String str = dr.documentID;
      if (myUserID == str || itemDS['rental'] != null) {
        canRequest = false;
      }

      ds = await Firestore.instance.collection('users').document(str).get();

      if (ds != null) {
        creatorDS = ds;
      }

      if (prefs != null && itemDS != null && creatorDS != null) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //textStyle = Theme.of(context).textTheme.title;

    return WillPopScope(
      onWillPop: () {
        goToLastScreen();
      },
      child: Scaffold(
        body: isLoading
            ? Container(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(child: CircularProgressIndicator())
              ]),
        )
            : showBody(),
        //floatingActionButton: showFAB(),
        bottomNavigationBar: isLoading
            ? Container(
          height: 0,
        )
            : bottomDetails(),
      ),
    );
  }

  Container bottomDetails() {
    return Container(
      height: 70.0,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
          color: Colors.black12,
          offset: new Offset(0, -0.5),
        )
      ]),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: showItemPrice(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 30.0),
            child: requestButton(),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  RaisedButton requestButton() {
    return RaisedButton(
        onPressed: canRequest ? () => handleRequestItemPressed() : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        color: Colors.red,
        child: Text("Check Availability",
            style: TextStyle(color: Colors.white, fontFamily: 'Quicksand')));
  }

  Widget showFAB() {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: RaisedButton(
        onPressed: () => navigateToEdit(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        color: Colors.red,
        child: Icon(Icons.edit),
      ),
    );
  }

  Future<DocumentSnapshot> getItemFromFirestore() async {
    DocumentSnapshot ds = await Firestore.instance
        .collection('items')
        .document(widget.itemID)
        .get();

    return ds;
  }

  Widget showBody() {
    return ListView(
      children: <Widget>[
        Stack(children: <Widget>[
          showItemImages(),
          backButton(),
        ]),
        showItemType(),
        showItemName(),
        showItemCondition(),
        showItemCreator(),
        showItemDescription(),
        divider(),
        showItemLocation(),
      ],
    );
  }

  Widget backButton() {
    return Container(
      alignment: Alignment.topLeft,
      child: FloatingActionButton(
        child: BackButton(),
        onPressed: () => goToLastScreen(),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget divider() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Divider(),
    );
  }

  Widget showItemCreator() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
      child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Shared by ${creatorDS['displayName']}',
                style: TextStyle(
                    color: Colors.black, fontSize: 15.0, fontFamily: 'Quicksand'),
                textAlign: TextAlign.left,
              ),
              Container(
                height: 50.0,
                child: ClipOval(
                  child: CachedNetworkImage(
                    key: new ValueKey<String>(
                        DateTime.now().millisecondsSinceEpoch.toString()),
                    imageUrl: creatorDS['photoURL'],
                    placeholder: (context, url) => new CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget showItemName() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0),
      child: SizedBox(
          child: Container(
            color: Color(0x00000000),
            child: Text(
              '${itemDS['name']}',
              //itemName,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Quicksand'),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemPrice() {
    return SizedBox(
      //height: 50.0,
        child: Container(
          color: Color(0x00000000),
          child: Row(
            children: <Widget>[
              Text(
                '\$${itemDS['price']}',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Quicksand'),
              ),
              Text(
                ' / HOUR',
                style: TextStyle(
                    color: Colors.black, fontSize: 12.0, fontFamily: 'Quicksand'),
              )
            ],
          ),
        ));
  }

  Widget showItemDescription() {
    return Padding(
      padding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      child: SizedBox(
          child: Container(
            color: Color(0x00000000),
            child: Text(
              '${itemDS['description']}',
              style: TextStyle(
                  color: Colors.black, fontSize: 15.0, fontFamily: 'Quicksand'),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemType() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0, top: 20.0),
      child: SizedBox(
          child: Container(
            color: Color(0x00000000),
            child: Text(
              '${itemDS['type']}'.toUpperCase(),
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Quicksand'),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemCondition() {
    return Padding(
      padding: EdgeInsets.only(left: 20.0, top: 5.0),
      child: SizedBox(
          child: Container(
            color: Color(0x00000000),
            child: Row(
              children: <Widget>[
                Text(
                  'Condition: ',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13.0,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Quicksand'),
                  textAlign: TextAlign.left,
                ),
                Text(
                  '${itemDS['condition']}',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.0,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Quicksand'),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          )),
    );
  }

  Widget showNumImages() {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: SizedBox(
          height: 50.0,
          child: Container(
            color: Color(0x00000000),
            child: Text(
              'Num images: ${itemDS['numImages']}',
              style: TextStyle(color: Colors.black, fontSize: 20.0),
              textAlign: TextAlign.left,
            ),
          )),
    );
  }

  Widget showItemImages() {
    double widthOfScreen = MediaQuery.of(context).size.width;
    List imagesList = itemDS['images'];
    return imagesList.length > 0
        ? Container(
      height: widthOfScreen,
      child: SizedBox.expand(child: getImagesListView(context)),
    )
        : Text('No images yet\n');
  }

  Widget showItemLocation() {
    double widthOfScreen = MediaQuery.of(context).size.width;
    GeoPoint gp = itemDS['location'];
    double lat = gp.latitude;
    double long = gp.longitude;
    setCamera();
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text('The Location',
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Quicksand')
                //textScaleFactor: 1.2,
              ),
            ),
          ),
          /*
          FlatButton(
            //materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: setCamera,
            child: Text(
              'Reset camera',
              textScaleFactor: 1,
              textAlign: TextAlign.center,
            ),
          ),
          */
          Center(
            child: SizedBox(
              width: widthOfScreen,
              height: 200.0,
              child: GoogleMap(
                mapType: MapType.normal,
                rotateGesturesEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: LatLng(lat, long),
                  zoom: 11.5,
                ),
                onMapCreated: (GoogleMapController controller) {
                  googleMapController = controller;
                },
                markers: Set<Marker>.of(
                  <Marker>[
                    Marker(
                      markerId: MarkerId("test_marker_id"),
                      position: LatLng(
                        lat,
                        long,
                      ),
                      infoWindow: InfoWindow(
                        title: 'Item Location',
                        snippet: '${lat}, ${long}',
                      ),
                    )
                  ],
                ),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  Factory<OneSequenceGestureRecognizer>(
                        () =>
                    // to disable dragging, use ScaleGestureRecognizer()
                    // to enable dragging, use EagerGestureRecognizer()
                    EagerGestureRecognizer(),
                    //ScaleGestureRecognizer(),
                  ),
                ].toSet(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  getImagesListView(BuildContext context) {
    double widthOfScreen = MediaQuery.of(context).size.width;
    List imagesList = itemDS['images'];
    return ListView.builder(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
      itemCount: imagesList.length,
      itemBuilder: (BuildContext context, int index) {
        return new Container(
          width: widthOfScreen,
          child: sizedContainer(
            new CachedNetworkImage(
              key: new ValueKey<String>(
                  DateTime.now().millisecondsSinceEpoch.toString()),
              imageUrl: imagesList[index],
              placeholder: (context, url) => new CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Widget sizedContainer(Widget child) {
    return new SizedBox(
      width: 300.0,
      height: 150.0,
      child: new Center(
        child: child,
      ),
    );
  }

  Item makeCopy(Item old) {
    Item output = Item();

    output.name = old.name;
    output.description = old.description;
    output.type = old.type;
    output.numImages = old.numImages;
    output.id = old.id;
    output.price = old.price;
    output.location = old.location;
    output.images = List();

    for (int i = 0; i < old.numImages; i++) {
      output.images.add(old.images[i]);
    }

    return output;
  }

  void navigateToEdit() async {
    Item editItem = Item.fromMap(itemDS.data);

    Item result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => ItemEdit(
            item: editItem,
          ),
          fullscreenDialog: true,
        ));

    if (result != null) {
      //updateParameters();
      //setCamera();
      setState(
            () {
          getSnapshots();
          //setCamera();
        },
      );
    }
  }

  void handleRequestItemPressed() async {
    /*
    setState(
      () {
        getSnapshots();
      },
    );
    */

    Navigator.pushNamed(
      context,
      ItemRequest.routeName,
      arguments: ItemRequestArgs(
        widget.itemID,
      ),
    );
/*
    Item result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => RequestItem(
                itemID: widget.itemID,
              ),
          fullscreenDialog: true,
        ));
        */
  }

  setCamera() async {
    GeoPoint gp = itemDS['location'];
    double lat = gp.latitude;
    double long = gp.longitude;

    LatLng newLoc = LatLng(lat, long);
    //final GoogleMapController controller = await _controller.future;
    googleMapController.animateCamera(CameraUpdate.newCameraPosition(
        new CameraPosition(target: newLoc, zoom: 11.5)));
  }

  void goToLastScreen() {
    Navigator.pop(context);
  }
}