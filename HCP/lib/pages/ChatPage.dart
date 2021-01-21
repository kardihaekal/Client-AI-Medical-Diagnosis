import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:rasa_chatbot/models/message.dart';
import 'package:rasa_chatbot/models/reply.dart';
import 'package:rasa_chatbot/models/sent.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatPage extends StatefulWidget {
  final Locale locale;

  ChatPage({@required this.locale});
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Message> messages;
  String url;
  Locale locale;

  stt.SpeechToText _speech;
  bool _isListening = false;
  var locales;
  String _text = '';
  double _confidence = 1.0;

  @override
  void initState() {
    locale = widget.locale;
    if (widget.locale.languageCode.toString() == "id") {
      url = "http://4d5b6c6f28be.ngrok.io/webhooks/rest/webhook";
    } 
    var mess;
    if (widget.locale.languageCode.toString() == "id") {
      mess = "Katakan, Halo dokter";
    }
    messages = [Message(text: mess, time: "123", isMe: false)];
    _speech = stt.SpeechToText();
    super.initState();
  }

  void _listen(String lang) async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: lang,
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else if (_text != '') {
      messages.add(Message(text: _text, time: "Time", isMe: true));
      messages.add(Message(text: "loading", time: "123", isMe: true));
      _networkReply(_text, "", "Time");
      _speech.stop();
      setState(() {
        _isListening = false;
        _text = '';
      });
    }
  }

  final controller = TextEditingController();

  _networkReply(String message, String sender, String time) async {
    Sent sentMessage = Sent(sender, message);
    var _jsonMessage = jsonEncode(sentMessage);
    Map<String, String> requestHeaders = {'Content-type': 'application/json'};
    print(_jsonMessage);
    var jsonResponse;
    var response =
        await http.post(url, body: _jsonMessage, headers: requestHeaders);
    var statusCode = response.statusCode;
    print(statusCode);
    if (statusCode == 200) {
      jsonResponse = json.decode(response.body);
      var parsedResponse = ReplyArray.fromJson(jsonResponse);
      var list = parsedResponse.replies;
      setState(() {
        messages.removeLast();
        messages.add(Message(text: list[0].text, time: time, isMe: false));
      });
    }
  }

  _buildMessage(Message message, bool isMe) {
    final Container msg = Container(
      margin: isMe
          ? EdgeInsets.only(
              right: 8.0,
              top: 8.0,
              bottom: 8.0,
              left: 80.0,
            )
          : EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0, right: 80.0),
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
      width: MediaQuery.of(context).size.width * 0.70,
      decoration: BoxDecoration(
        color: isMe ? Color(0xff1e5f74) : Color(0xFF133b5c),
        borderRadius: isMe
            ? BorderRadius.only(
                topLeft: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              )
            : BorderRadius.only(
                topRight: Radius.circular(15.0),
                bottomRight: Radius.circular(15.0),
                bottomLeft: Radius.circular(15.0),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message.text,
            style: TextStyle(
              color: Color(0xffF5F7DC),
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff1d2d50),
      appBar: AppBar(
        backgroundColor: Color(0xff1d2d50),
        title: Text(
          "HCP",
          style: TextStyle(
            color: Color(0xffF5F7DC),
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more_horiz),
            iconSize: 30.0,
            color: Colors.white,
            onPressed: () {},
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xff0F0326),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                  child: ListView.builder(
                    reverse: false,
                    padding: EdgeInsets.only(top: 15.0),
                    itemCount: messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      Message message = messages[index];
                      bool isMe = message.isMe;
                      if (message.text == "loading")
                        return SpinKitWave(
                          color: Color(0xffF5F7DC),
                          type: SpinKitWaveType.start,
                          size: 25.0,
                        );
                      else
                        return _buildMessage(message, isMe);
                    },
                  ),
                ),
              ),
            ),
            Text(_text,
                style: TextStyle(
                  color: Color(0xffF5F7DC),
                )),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ClipOval(
                  child: Material(
                    color: Colors.blue,
                    child: InkWell(
                      splashColor:Colors.red,
                      child: SizedBox(width: 56, height: 56, child: Icon(Icons.mic)),
                      onTap:() =>{_isListening ? "Stop" : "Stop", _listen("id")}
                    ),
                  ),
                ),
              ],
            ),
           
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}
