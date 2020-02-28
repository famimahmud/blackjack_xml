/*
WS Endpoint
This file has to be imported on the site where WebSocket functionality
should be used. The following functions and the HTML WebSocket Element are
meant to be used with any STOMP server supporting STOMP v1.2, but could be adapted for other
WebSocket applications as well.

This contains the code for the HTML WebSocket element
Other than importing this JS file, the HTML element has to be declared on the
page and the code will be executed automatically by the browser while parsing
the HTML document. Refer to the HTML WebSocket Element documentation to find out which
attributes are mandatory and how to use them.
*/

$(document).ready(function () {
    class WS_Stream extends HTMLElement {
        constructor() {
          super();
          this.streamElement = this;
          this.globalConnectionWSElement = undefined;
          this.wsElementParams = undefined;
      }

      connectedCallback(){
        this.streamElement.connect();
      }

      connect(){
            let streamElement = this;

            // Get the HTML WebSocket element attributes
            this.wsElementParams = {
                id: this.streamElement.getAttribute('id'),
                idString: "#" + this.streamElement.getAttribute('id'),
                url: this.streamElement.getAttribute('url'),
                init: this.streamElement.getAttribute('init'),
                subscription: this.streamElement.getAttribute('subscription')
            }
            
            console.log(this.streamElement.getAttribute('login'));
            let login = this.streamElement.getAttribute('login');
            let passcode = this.streamElement.getAttribute('passcode')

            let headers = {
                login: login !== null ? login : "login",
                passcode: passcode !== null ? passcode : "pass"
            }

            let heartbeatOutgoing = this.streamElement.getAttribute('heartbeatOutgoing');
            let heartbeatIncoming = this.streamElement.getAttribute('heartbeatIncoming');
            let reconnectDelay = this.streamElement.getAttribute('reconnectDelay');

            let stompParams = {
                protocols: ['v12.stomp'],
                heartbeatOutgoing: heartbeatOutgoing !== null ? heartbeatOutgoing : 10000,
                heartbeatIncoming: heartbeatIncoming !== null ? heartbeatIncoming : 10000,
                reconnectDelay: reconnectDelay !== null ? reconnectDelay : 0
            }
            console.log('IDString '+this.wsElementParams.idString);

            if(this.wsElementParams.url != null){
                let ws = Stomp.client(this.wsElementParams.url, stompParams.protocols);
                ws.debug = function(str) {
                    console.log(str + "\n");
                  };
                ws.heartbeat.outgoing = stompParams.heartbeatOutgoing;
                ws.heartbeat.incoming = stompParams.heartbeatIncoming;
                ws.reconnect_delay = stompParams.reconnectDelay;

                let stompConnectedCallback = function(){
                    console.log("ID: " + streamElement.wsElementParams.id + " - Connected to STOMP server");

                    let stompOnMessage = function(message){
                        if(streamElement.hasAttribute('xslt')){
                            let xsltURL = streamElement.getAttribute('xslt');
                            let xslParam = streamElement.getAttribute('xslparam');
        
                            if(xslParam !== undefined){
                                let xslParamsJSON = streamElement.parseXSLTParams(xslParam);
                                console.log("xslParamsJSON: " + JSON.stringify(xslParamsJSON));
                            }
        
                            let promise = streamElement.transform(message.body, xsltURL, xslParamsJSON);
                            promise.then(function(result) {
                                console.log("Transformed document " + result)
                                $(streamElement.wsElementParams.idString).html(result);
                            });
                        }

                        console.log("ID: " + streamElement.wsElementParams.id + " - MSG: " + message);
                        $(streamElement.wsElementParams.idString).html(message.body);
                    }

                    if(streamElement.wsElementParams.subscription !== null){
                        let destinationArray = streamElement.wsElementParams.subscription.split("/").filter(element => element.length !== 0);
                        console.log(destinationArray);
                        let destinationPath = "";
                        let pathsArray = [];
                        let subscribeParam = {};
                        for(let i = 0; i < destinationArray.length; i++){
                            subscribeParam['param' + i] = destinationArray[i];
                            if (i === 0 && i === destinationArray.length - 1){
                                destinationPath += "/" + destinationArray[i];
                            } else if (i === 0){
                                destinationPath += "/" + destinationArray[i];
                            }else if (i === destinationArray.length - 1){
                                destinationPath += "/" + destinationArray[i];
                            }else{
                                destinationPath += "/" + destinationArray[i];
                            }
                            pathsArray.push(destinationPath);
                        };
                        let subscriptions = [];

                        pathsArray.forEach((value, i) => {
                            let headers = subscribeParam.id = "id"+i;
                            subscriptions.push(ws.subscribe(value, stompOnMessage, subscribeParam));
                            console.log(subscribeParam);
                        }); 
                        console.log(pathsArray);
                        console.log(subscriptions);
                    }
                    streamElement.initElement();
                }

                let stompErrorCallback = function(error){
                    console.log("ID: " + streamElement.wsElementParams.id + " - Error while connecting to server: " + error);
                }

                let stompCloseCallback = function(){
                    console.log("ID: " + streamElement.wsElementParams.id + " - Closed connection");
                    if(streamElement.getAttribute('oncloseurl') !== null){
                        window.location = streamElement.getAttribute('oncloseurl');
                    }else{
                      $(streamElement.wsElementParams.idString).html("WebSocket connection closed");
                    }
                }

                ws.connect(headers, stompConnectedCallback, stompErrorCallback, stompCloseCallback);
                this.globalConnectionWSElement = ws;
            }
            else{
                console.log("Error: No URL defined for the WebSocket connection!")
            }

      }

      parseXSLTParams(xslParam){
        let xslParamRawString = '{';
        let params = xslParam.split(',');
        console.log(params);

        for (let i = 0; i < params.length; i++) {
            let pairs = params[i].split('=');
            console.log(pairs);
            if(i === params.length - 1){
                xslParamRawString +=  '"' + pairs[0].trim() + '":' + '"'+pairs[1].trim() + '"';
                xslParamRawString += '}';
            }
            else{
                xslParamRawString +=  '"' + pairs[0].trim() + '":' + '"'+pairs[1].trim() + '",';
            }
        }
        console.log(xslParamRawString);
        let finalJSON;
        try {
            finalJSON = JSON.parse(xslParamRawString);
        } catch(finalJSON) {
            alert('Error in format of XSLT parameters');
        }
        console.log("Final JSON XSLT parameters: "+finalJSON);
        return finalJSON;
      }

      transform(xml, stylesheetURL, params) {
          let promise = new Promise(function(resolve, reject) {
            let __domParser = new DOMParser();
            let domNode = __domParser.parseFromString(xml, "application/xml");

            console.log("Requesting stylesheet url " + stylesheetURL)
            let serialized;
            $.get(stylesheetURL, function(resp, other){
                let xsltProcessor = new XSLTProcessor();
                xsltProcessor.importStylesheet(resp);

                for (let k in params) {
                    xsltProcessor.setParameter(null, k, params[k]);
                }
                let resultDocument = xsltProcessor.transformToDocument(domNode);
                serialized = new XMLSerializer().serializeToString(resultDocument);

                console.log("Serialized document " + serialized);
                if (serialized !== undefined) {
                    resolve(serialized);
                }
                else {
                    reject(Error("Error transforming the document"));
                }
            });
          });
          return promise;
      }

      initElement() {
          let streamElement = this;
          console.log('Geturl: ' + this.streamElement.getAttribute('geturl'));
          if(this.streamElement.hasAttribute('geturl')){
              $.get(this.streamElement.getAttribute('geturl'), function(resp, other) {
                  console.log('Geturl response: ' + resp);
                  if(resp !== null){
                    $(streamElement.wsElementParams.idString).html(resp);
                  }
                  });

          }else if(this.streamElement.hasAttribute('init') && !(this.streamElement.hasAttribute('geturl'))){
            $(streamElement.wsElementParams.idString).html(this.streamElement.getAttribute('init'));
          }
        }

        disconnectedCallback(){
            this.globalConnectionWSElement.disconnect(()=>{console.log("Disconnected")}, headers= {});
        }
      }

      // Define the new element
      customElements.define('ws-stream', WS_Stream);
});
