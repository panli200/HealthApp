import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as Cloud;
import 'package:firebase_database/firebase_database.dart';
import 'package:sos_app/sos_extended_pages/signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sos_app/sos_extended_pages/videostream.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CallPage extends StatefulWidget {
  final privateKey;
  final publicKey;
  final aesKey;
  CallPage(
      {Key? key,
      required this.privateKey,
      required this.publicKey,
      required this.aesKey})
      : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late final publicKey;
  late final privateKey;
  late final otherEndPublicKey;
  late final aesSecretKey;
  late final aesSecretKeyString;
  final algorithm = AesCtr.with256bits(macAlgorithm: Hmac.sha256());
  final senttext = new TextEditingController();
  DatabaseReference ref = FirebaseDatabase.instance.ref();
  String mobile = FirebaseAuth.instance.currentUser!.phoneNumber.toString();
  StreamSubscription? streamSubscriptionEnded;
  bool? Ended;

  //Video Stream
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  Future<String> decryptText(SecretBox secretBox) async {
    return utf8.decode(
        await algorithm.decrypt(secretBox, secretKey: await aesSecretKey));
  }

  /// Encrypt and sent to database
  void encryptTextAndSend(String text) async {
    // message to bytes
    var message = utf8.encode(text);
    // secret box
    final secretBox = await algorithm.encrypt(
      message,
      secretKey: await aesSecretKey,
    );
    // send secret box attributes
    String nonce = secretBox.nonce.toString();
    String cipher = secretBox.cipherText.toString();
    String mac = secretBox.mac.bytes.toString();
    String mobile = FirebaseAuth.instance.currentUser!.phoneNumber.toString();
    Cloud.FirebaseFirestore.instance
        .collection('SOSEmergencies')
        .doc(mobile)
        .collection('messages')
        .add({
      'Message': message,
      'SAdmin': false,
      'time': Cloud.FieldValue.serverTimestamp(),
      'nonce': nonce,
      'cipher': cipher,
      'mac': mac
    });
  }

  @override
  void initState() {
    publicKey = widget.publicKey;
    privateKey = widget.privateKey;
    aesSecretKey = widget.aesKey;
    final databaseReal = ref.child('sensors').child(mobile);
    streamSubscriptionEnded =
        databaseReal.child('Ended').onValue.listen((event) async {
      bool? EndedB = event.snapshot?.value as bool;
      Ended = EndedB;
      if (Ended == true) {
        var router = context.router;
        router.popUntilRoot();
      }
    });
    StreamSubscription? publicKeyStream;
    streamSubscriptionEnded = databaseReal
        .child('dispatcher_public_key')
        .onValue
        .listen((event) async {
      late String? publicPassed;
      publicPassed = event.snapshot?.value.toString();

      if (Ended != true && publicPassed != null) {
        var helper = RsaKeyHelper();
        otherEndPublicKey = helper.parsePublicKeyFromPem(publicPassed);
      }
    });

    //Video Stream
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    streamSubscriptionEnded!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String mobile = FirebaseAuth.instance.currentUser!.phoneNumber.toString();
    final Cloud.Query sorted = Cloud.FirebaseFirestore.instance
        .collection('SOSEmergencies')
        .doc(mobile)
        .collection('messages')
        .orderBy("time", descending: true);

    int localMessageIndex = 0;
    final Stream<Cloud.QuerySnapshot> messages = sorted.snapshots();

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "911 Dispatcher",
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          actions: <Widget>[
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('SOSEmergencies')
                    .doc(mobile)
                    .update({'Online': false, 'Ended': true});

                signaling!.hangUp(_localRenderer!);
                DatabaseReference real = FirebaseDatabase.instance.ref();
                final databaseReal = real.child('sensors').child(mobile);

                await databaseReal.update({'Online': false, 'Ended': true});
              },
              child: Text("End"),
            ),
            IconButton(
                icon: Icon(Icons.call, color: Colors.black),
                onPressed: () async {
                  signaling.openUserAudio(_localRenderer, _remoteRenderer);
                  roomId = await signaling.createRoom(_remoteRenderer);
                  setState(() {});
                  showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                            actions: <Widget>[
                              new IconButton(
                                  alignment: Alignment.center,
                                  icon: new Icon(
                                    Icons.phone,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    signaling.hangUp(_localRenderer);
                                    Navigator.of(context).pop(null);
                                  }),
                            ],
                          ));
                }),
            IconButton(
                icon: Icon(Icons.video_call_rounded, color: Colors.black),
                onPressed: () async {
                  signaling.openUserMedia(_localRenderer, _remoteRenderer);
                  roomId = await signaling.createRoom(_remoteRenderer);
                  setState(() {});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => VideoStream(
                            signaling: signaling,
                            localRenderer: _localRenderer)),
                  );
                }),
          ],
        ),
        body: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: <Widget>[
                Expanded(
                    child: StreamBuilder<Cloud.QuerySnapshot>(
                        stream: messages,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<Cloud.QuerySnapshot> snapshot,
                        ) {
                          if (snapshot.hasError) {
                            return Text('Something went wrong');
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text('Loading');
                          }

                          final data = snapshot.requireData;
                          return ListView.builder(
                              reverse: true,
                              itemCount: data.size,
                              itemBuilder: (context, index) {
                                Color c;
                                Alignment a;
                                if (data.docs[index]['SAdmin'] == false) {
                                  c = Colors.blueGrey;
                                  a = Alignment.centerRight;
                                } else {
                                  // Dispatcher
                                  c = Colors.lightGreen;
                                  a = Alignment.centerLeft;
                                }
                                // getting values of SecretBox as string
                                var nonceString = data.docs[index]['nonce'];
                                var cipherString = data.docs[index]['cipher'];
                                var macString = data.docs[index]['mac'];

                                var macBytes =
                                    (jsonDecode(macString) as List<dynamic>)
                                        .cast<int>();
                                Mac macFinal = Mac(macBytes);
                                List<int> nonceInt =
                                    (jsonDecode(nonceString) as List<dynamic>)
                                        .cast<int>();
                                List<int> cipherInt =
                                    (jsonDecode(cipherString) as List<dynamic>)
                                        .cast<int>();
                                SecretBox newBox = SecretBox(cipherInt,
                                    nonce: nonceInt, mac: macFinal);
                                return FutureBuilder(
                                    future: decryptText(newBox),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<dynamic> snapshot) {
                                      if (snapshot.hasError) {
                                        return Text('Something went wrong');
                                      }
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }

                                      String decryptedMessage = snapshot.data;
                                      return Align(
                                          alignment: a,
                                          child: Container(
                                            child: Text(
                                              decryptedMessage,
                                              style: const TextStyle(
                                                  color: Colors.black),
                                            ),
                                            constraints: const BoxConstraints(
                                              maxHeight: double.infinity,
                                            ),
                                            padding: EdgeInsets.all(10.0),
                                            margin: EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              color: c,
                                              borderRadius:
                                                  BorderRadius.circular(35.0),
                                              boxShadow: const [
                                                BoxShadow(
                                                    offset: Offset(0, 2),
                                                    blurRadius: 2,
                                                    color: Colors.grey)
                                              ],
                                            ),
                                          ));
                                    });
                              });
                        })),
                Container(
                  height: 70,
                  constraints: const BoxConstraints(
                    maxHeight: double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(35.0),
                    boxShadow: const [
                      BoxShadow(
                          offset: Offset(0, 2),
                          blurRadius: 2,
                          color: Colors.grey)
                    ],
                  ),
                  padding: EdgeInsets.all(10.0),
                  margin: EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: senttext,
                          style: TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                              hintText: "Type Something...",
                              hintStyle: TextStyle(color: Colors.black),
                              border: InputBorder.none),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          String text = senttext.text;
                          if (text != '') {
                            // Store message locally in the List
                            // encrypt using the Other end's public key
                            encryptTextAndSend(text);
                            senttext.text = '';
                          }
                        },
                      )
                    ],
                  ),
                ),
              ],
            )));
  }
}
